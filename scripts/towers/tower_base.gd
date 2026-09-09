extends Node2D
## Base tower class: shared logic for all tower types.
## Subclasses must define STATS_PER_LEVEL dictionary and UPGRADE_COSTS array.

## Safety cap on in-flight projectiles. Set in scene file per tower type.
@export var MAX_PROJECTILES := 8

## Projectile scene to use. Override in subclass for custom projectiles.
@onready var PROJECTILE_SCENE := preload("res://scenes/projectiles/basic_projectile.tscn")

@export var range: float = 180.0
@export var damage: int = 1
@export var attack_cooldown: float = 0.8
@export var cost: int = 50

## Current tower level (1-based). Starts at 1, max 3.
var level: int = 1

## Max level for this tower type. Subclasses should override.
var max_level: int = 3

## Stats for each level: Array of Dictionaries {damage, range, attack_cooldown}
## Index 0 = level 1, index 1 = level 2, etc.
var STATS_PER_LEVEL: Array = []

## Upgrade costs per level: Array of ints where index i = cost to upgrade from level i+1 to i+2
## So UPGRADE_COSTS[0] = cost from level 1->2, UPGRADE_COSTS[1] = cost from level 2->3
var UPGRADE_COSTS: Array = []

## Attack speed in attacks per second (derived from cooldown for UI).
@export var attack_speed: float:
	get:
		return 1.0 / attack_cooldown

signal fired
signal impact(position: Vector2)
signal upgraded(new_level: int)

var _targets: Array = []
var _cooldown_left: float = 0.0
var _detection_area: Area2D = null

func _ready() -> void:
	_detection_area = $DetectionArea
	$DetectionArea/CollisionShape2D.shape.radius = range
	$DetectionArea.area_entered.connect(_on_area_entered)
	$DetectionArea.area_exited.connect(_on_area_exited)
	_apply_level_stats()

func _on_area_entered(area: Area2D) -> void:
	var enemy: Node2D = area.get_parent()
	if enemy != null and enemy.has_method("take_damage"):
		if not _targets.has(enemy):
			_targets.append(enemy)

func _on_area_exited(area: Area2D) -> void:
	var enemy: Node2D = area.get_parent()
	_targets.erase(enemy)

## Actively scans for enemies in range each physics frame to catch fast
## movers that tunnel through the detection area without triggering signals.
## Enemies expose an Area2D hitbox, so areas (not bodies) are queried.
func _scan_range() -> void:
	var areas := _detection_area.get_overlapping_areas()
	for area in areas:
		var enemy: Node2D = area.get_parent()
		if enemy != null and enemy.has_method("take_damage"):
			if not _targets.has(enemy):
				_targets.append(enemy)

## Targets are kept tidy by the area_entered/area_exited signals and the
## active scan. We clean stale entries when about to fire.
func _physics_process(delta: float) -> void:
	_scan_range()
	
	if _targets.is_empty():
		_cooldown_left = 0.0
		return

	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return

	var target := _get_furthest_target()
	if target == null:
		_clean_dead_targets()
		_cooldown_left = attack_cooldown
		return

	_fire(target)
	_cooldown_left = attack_cooldown

func _clean_dead_targets() -> void:
	var i := 0
	while i < _targets.size():
		if not is_instance_valid(_targets[i]):
			_targets.remove_at(i)
		else:
			i += 1

## Returns the enemy furthest along the path (highest path_progress).
## Runs only when the tower is about to fire; filtered to enemies within range.
func _get_furthest_target() -> Node2D:
	var best: Node2D = null
	var best_progress := -1.0
	for enemy in _targets:
		if not is_instance_valid(enemy):
			continue
		var prog: float = enemy.path_progress
		if prog > best_progress:
			best_progress = prog
			best = enemy
	return best

func _fire(target: Node2D) -> void:
	var in_flight := 0
	for child in get_children():
		if child.name == "BasicProjectile":
			in_flight += 1
	if in_flight >= MAX_PROJECTILES:
		push_warning("%s dropped a shot: in-flight projectile cap reached (%d)." % [self.name, MAX_PROJECTILES])
		return

	var proj := _make_projectile()
	proj.init(damage, target)
	# The projectile is a child of the tower, so position is local to it.
	# Spawn slightly above the tower's center so it looks like it was fired.
	proj.position = Vector2(0, -32)
	add_child(proj)

	# Forward projectile impact to tower level for visual effects
	proj.impact.connect(_on_projectile_impact)

	# Fire feedback
	_fire_feedback()
	fired.emit()

## Override in subclass for custom projectile types.
func _make_projectile() -> Node2D:
	return PROJECTILE_SCENE.instantiate()

func _on_projectile_impact(position: Vector2) -> void:
	impact.emit(position)

func _fire_feedback() -> void:
	# Brief scale pulse + white flash via modulate
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

## Applies the current level's stats to the tower's properties.
## Called on _ready and after each upgrade.
func _apply_level_stats() -> void:
	if level < 1 or level > STATS_PER_LEVEL.size():
		return
	var stats: Dictionary = STATS_PER_LEVEL[level - 1]
	damage = stats.damage
	range = stats.range
	attack_cooldown = stats.attack_cooldown
	# Update detection area radius
	if is_instance_valid($DetectionArea) and is_instance_valid($DetectionArea/CollisionShape2D):
		$DetectionArea/CollisionShape2D.shape.radius = range

## Returns the cost to upgrade to the next level, or -1 if at max level.
func get_upgrade_cost() -> int:
	if level >= max_level or level > UPGRADE_COSTS.size():
		return -1
	return UPGRADE_COSTS[level - 1]

## Attempts to upgrade the tower to the next level.
## Returns true if upgrade succeeded, false otherwise.
func try_upgrade() -> bool:
	if level >= max_level:
		return false
	var cost := get_upgrade_cost()
	if cost < 0:
		return false
	level += 1
	_apply_level_stats()
	_upgrade_feedback()
	upgraded.emit(level)
	return true

## Visual feedback when tower upgrades.
func _upgrade_feedback() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.5, 1.5, 0.5, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)