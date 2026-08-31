extends Node2D
## Base enemy class: shared logic for all enemy types.
## Subclasses set stats via @export properties (no defaults here) or scene file.

signal died(reward_amount: int)
signal reached_base

@export var speed: float
@export var health: int
@export var reward: int
@export var base_damage: int

## Guarantees the enemy finishes exactly once (dies OR reaches the base), never
## both, so its reward/damage signals are emitted at most one time.
var _resolved := false

func _physics_process(delta: float) -> void:
	var follow := get_parent() as PathFollow2D
	if follow == null:
		return

	follow.progress += speed * delta

	if follow.progress_ratio >= 1.0:
		_reach_end()

## Applies damage to the enemy. When health reaches zero the enemy dies and
## emits the `died` signal (for reward), then frees its PathFollow2D.
func take_damage(amount: int) -> void:
	if _resolved or health <= 0:
		return
	health -= amount
	# Damage feedback: brief white flash
	modulate = Color(1.5, 1.5, 1.5, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
	if health <= 0:
		_die()

func _die() -> void:
	if _resolved:
		return
	_resolved = true
	died.emit(reward)
	_free_follow()

## Called when the enemy completes the path. Emits `reached_base` so the game
## can damage the base (no reward for a leaked enemy), then frees itself.
func _reach_end() -> void:
	if _resolved:
		return
	_resolved = true
	reached_base.emit()
	_free_follow()

func _free_follow() -> void:
	var parent := get_parent()
	if is_instance_valid(parent) and parent is PathFollow2D:
		parent.queue_free()
	elif is_inside_tree():
		queue_free()