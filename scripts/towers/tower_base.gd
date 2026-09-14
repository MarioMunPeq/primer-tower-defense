extends Node2D
## Base tower class: shared logic for all tower types.
## Subclasses define the level-1 stats table plus two specialization branches
## (A = damage, B = speed/utility). Picking a branch at level 1 locks the tower
## into it for the remaining upgrades.

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

## Level 1 base stats: Array of one Dictionary {damage, range, attack_cooldown}.
var STATS_PER_LEVEL: Array = []

## Branch tables: index 0 = level 2, index 1 = level 3 for that branch.
## Each Dictionary: {damage, range, attack_cooldown} plus an optional
## "special" key that overrides the tower's `special_value`.
var BRANCH_A_STATS: Array = []
var BRANCH_B_STATS: Array = []

## Branch upgrade costs: index 0 = cost to pick the branch (level 1 -> 2),
## index 1 = cost to keep upgrading inside it (level 2 -> 3).
var BRANCH_A_COSTS: Array = []
var BRANCH_B_COSTS: Array = []

## Chosen specialization branch: "" (not chosen yet), "A" (damage) or "B"
## (speed / utility). Set once at level 1, never changes afterwards.
var branch: String = ""
## Human-readable branch names shown on the branch-choice buttons.
var branch_name_a := "DAMAGE"
var branch_name_b := "SPEED"

## Special effect descriptor. `special_id` drives the effect behaviour:
##   "splash"       -> AoE damage around the impact point (radius in px)
##   "slow"         -> movement slow on the direct target (factor 0..1)
##   "frost"        -> AoE slow around the impact point (radius + factor)
##   "armor_pierce" -> direct hits ignore enemy damage_reduction
var special_id := "none"
var special_name := ""
var special_value := 0.0        ## splash/frost radius (px) or slow factor (0..1)
var special_extra := 0.0        ## frost slow factor (0..1)
var special_duration := 1.0     ## slow/frost duration in seconds
var armor_pierce := false       ## "armor_pierce" behaviour flag

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
	proj.init(damage, target, armor_pierce)
	# The projectile is a child of the tower, so position is local to it.
	# Spawn slightly above the tower's center so it looks like it was fired.
	proj.position = Vector2(0, -32)
	add_child(proj)

	# Forward projectile impact to tower level for visual effects, and forward
	# the exact hit enemy so special effects (splash/slow/frost) can resolve.
	proj.impact.connect(_on_projectile_impact)
	proj.did_hit.connect(_on_projectile_did_hit)

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
## Level 1 reads the base table; level 2+ reads the chosen branch's table.
## Called on _ready and after each upgrade or branch choice.
func _apply_level_stats() -> void:
	if level < 1:
		return
	var stats: Dictionary
	if level == 1:
		stats = STATS_PER_LEVEL[0]
	else:
		var arr := BRANCH_A_STATS if branch == "A" else BRANCH_B_STATS
		var idx := level - 2
		if idx < 0 or idx >= arr.size():
			return
		stats = arr[idx]
	damage = stats["damage"]
	range = stats["range"]
	attack_cooldown = stats["attack_cooldown"]
	if stats.has("special"):
		special_value = stats["special"]
	if stats.has("special_extra"):
		special_extra = stats["special_extra"]
	# Update detection area radius
	if is_instance_valid($DetectionArea) and is_instance_valid($DetectionArea/CollisionShape2D):
		$DetectionArea/CollisionShape2D.shape.radius = range

## Cost to take a branch at level 1 ("A"/"B"), or to keep upgrading along the
## currently chosen branch at level 2+. Returns -1 when the branch is not
## available (already taken by the other one, or the tower is past that step).
func get_branch_cost(branch_id: String) -> int:
	if branch_id != "A" and branch_id != "B":
		return -1
	if level >= 2 and branch_id != branch:
		return -1
	var costs := BRANCH_A_COSTS if branch_id == "A" else BRANCH_B_COSTS
	var idx := 0 if level == 1 else level - 2
	if idx < 0 or idx >= costs.size():
		return -1
	return costs[idx]

## Returns the cost to upgrade to the next level along the chosen branch,
## or -1 if there is none (level 1 still needs a branch choice; level 3 is max).
func get_upgrade_cost() -> int:
	if level == 1 or level >= max_level:
		return -1
	var costs := BRANCH_A_COSTS if branch == "A" else BRANCH_B_COSTS
	var idx := level - 1
	if idx < 0 or idx >= costs.size():
		return -1
	return costs[idx]

## Picks a specialization branch at level 1 and advances the tower to level 2.
## Returns true if the branch was taken, false otherwise.
func try_set_branch(branch_id: String) -> bool:
	if level != 1 or (branch_id != "A" and branch_id != "B"):
		return false
	branch = branch_id
	level = 2
	_apply_level_stats()
	_upgrade_feedback()
	upgraded.emit(level)
	return true

## Attempts to upgrade the tower along its chosen branch (level 2 -> 3).
## Returns true if the upgrade succeeded, false otherwise.
func try_upgrade() -> bool:
	if level == 1 or level >= max_level:
		return false
	var cost := get_upgrade_cost()
	if cost < 0:
		return false
	level += 1
	_apply_level_stats()
	_upgrade_feedback()
	upgraded.emit(level)
	return true

## Paid upgrade history, oldest first: [branch choice] at level 2, plus the
## branch re-upgrade cost at level 3. Used by the sell refund calculation.
func paid_upgrade_costs() -> Array:
	if level <= 1:
		return []
	var first_costs := BRANCH_A_COSTS if branch == "A" else BRANCH_B_COSTS
	if level == 2 or first_costs.size() < 2:
		return [first_costs[0]]
	return [first_costs[0], first_costs[1]]

## Visual feedback when tower upgrades.
func _upgrade_feedback() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(0.5, 1.5, 0.5, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

## Fired by every projectile when it connects with an enemy: resolves the
## tower's special effect (splash, slow, frost, armor pierce).
func _on_projectile_did_hit(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	match special_id:
		"splash":
			_apply_splash(enemy)
		"slow":
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(special_value, special_duration)
		"frost":
			_apply_frost(enemy)
		"armor_pierce":
			pass  # handled at damage time via the projectile's pierce flag

func _apply_splash(center: Node2D) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e == center or not e.has_method("take_damage"):
			continue
		if e.global_position.distance_to(center.global_position) <= special_value:
			e.take_damage(damage)

func _apply_frost(center: Node2D) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("apply_slow"):
			continue
		if e.global_position.distance_to(center.global_position) <= special_value:
			e.apply_slow(special_extra, special_duration)

## Human-readable special value for panels and tooltips.
func special_value_text() -> String:
	match special_id:
		"splash":
			return "%d px" % int(special_value)
		"slow":
			return "%d%% · %ds" % [int(special_value * 100.0), int(special_duration)]
		"frost":
			return "%d px · %d%%" % [int(special_value), int(special_extra * 100.0)]
		"armor_pierce":
			return "ON"
	return ""