extends Node2D
## Basic projectile: flies toward a target enemy and deals damage on impact,
## freeing itself once it hits (or if the target is gone).

@export var speed: float = 400.0
## Lifetime safety rail: if a projectile can never catch its target (edge case)
## it frees itself after this many seconds instead of running forever under a
## tower and accumulating.
const MAX_LIFETIME := 5.0

signal impact
## Fired right after impact, carrying the exact enemy that was hit. Towers use
## this to apply special effects (splash damage, slows) without hard-coding who
## took the direct hit.
signal did_hit(enemy: Node2D)

var _damage: int = 1
var _target: Node2D = null
var _pierce := false
var _age := 0.0
var _resolved := false

func init(dmg: int, target: Node2D, pierce := false) -> void:
	_damage = dmg
	_target = target
	_pierce = pierce

func _physics_process(delta: float) -> void:
	if _resolved:
		return
	if not is_instance_valid(_target):
		_free_self()
		return

	_age += delta
	if _age >= MAX_LIFETIME:
		_free_self()
		return

	var to_target := _target.global_position - global_position
	var distance := to_target.length()
	var step := speed * delta

	if distance <= step:
		if _target.has_method("take_damage"):
			_target.take_damage(_damage, _pierce)
		impact.emit(global_position)
		did_hit.emit(_target)
		_free_self()
		return

	global_position += to_target.normalized() * step

func _free_self() -> void:
	if _resolved:
		return
	_resolved = true
	queue_free()
