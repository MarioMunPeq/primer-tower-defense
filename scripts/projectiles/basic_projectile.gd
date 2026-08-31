extends Node2D
## Basic projectile: flies toward a target enemy and deals damage on impact,
## freeing itself once it hits (or if the target is gone).

@export var speed: float = 400.0

var _damage: int = 1
var _target: Node2D = null

func init(dmg: int, target: Node2D) -> void:
	_damage = dmg
	_target = target

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		queue_free()
		return

	var to_target := _target.global_position - global_position
	var distance := to_target.length()
	var step := speed * delta

	if distance <= step:
		if _target.has_method("take_damage"):
			_target.take_damage(_damage)
		queue_free()
		return

	global_position += to_target.normalized() * step
