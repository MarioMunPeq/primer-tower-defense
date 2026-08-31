extends Node2D
## Basic tower: detects enemies inside its range (Area2D) and fires
## basic_projectile instances at the nearest target every attack_cooldown.

@export var range: float = 180.0
@export var damage: int = 1
@export var attack_cooldown: float = 0.8

const BASIC_PROJECTILE := preload("res://scenes/projectiles/basic_projectile.tscn")

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

func _physics_process(delta: float) -> void:
	_clean_dead_targets()
	if _targets.is_empty():
		return

	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return

	var target := _get_nearest_target()
	if target == null:
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

## Returns the closest valid enemy. Priority/first-target logic can be added
## here in a future milestone; for now we always shoot the nearest one.
func _get_nearest_target() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for enemy in _targets:
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best

func _fire(target: Node2D) -> void:
	var proj := BASIC_PROJECTILE.instantiate()
	proj.init(damage, target)
	# The projectile is a child of the tower, so position is local to it.
	# Spawn slightly above the tower's center so it looks like it was fired.
	proj.position = Vector2(0, -32)
	add_child(proj)
