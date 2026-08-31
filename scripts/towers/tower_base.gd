extends Node2D
## Base tower class: shared logic for all tower types.
## Subclasses only need to set @export stats (range, damage, attack_cooldown, cost, MAX_PROJECTILES).
## Uses basic_projectile by default; override _make_projectile() for custom projectiles.

## Safety cap on in-flight projectiles. Set in scene file per tower type.
@export var MAX_PROJECTILES := 8

## Projectile scene to use. Override in subclass for custom projectiles.
@onready var PROJECTILE_SCENE := preload("res://scenes/projectiles/basic_projectile.tscn")

@export var range: float = 180.0
@export var damage: int = 1
@export var attack_cooldown: float = 0.8
@export var cost: int = 50

## Attack speed in attacks per second (derived from cooldown for UI).
@export var attack_speed: float:
	get:
		return 1.0 / attack_cooldown

signal fired
signal impact(position: Vector2)

var _targets: Array = []
var _cooldown_left: float = 0.0

func _ready() -> void:
	$DetectionArea/CollisionShape2D.shape.radius = range
	$DetectionArea.area_entered.connect(_on_area_entered)
	$DetectionArea.area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	var enemy: Node2D = area.get_parent()
	if enemy != null and enemy.has_method("take_damage"):
		if not _targets.has(enemy):
			_targets.append(enemy)

func _on_area_exited(area: Area2D) -> void:
	var enemy: Node2D = area.get_parent()
	_targets.erase(enemy)

## Targets are kept tidy by the area_entered/area_exited signals (a freed enemy
## automatically fires area_exited), so we only scan the list when about to fire.
func _physics_process(delta: float) -> void:
	if _targets.is_empty():
		_cooldown_left = 0.0
		return

	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return

	var target := _get_nearest_target()
	if target == null:
		# List may hold stale entries whose area_exited hasn't landed yet.
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

## Returns the closest valid enemy. Runs only when the tower is about to fire,
## not every frame, so cost stays proportional to firing rate.
func _get_nearest_target() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for enemy in _targets:
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_squared_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
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