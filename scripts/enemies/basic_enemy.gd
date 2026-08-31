extends Node2D
## Basic enemy that follows the EnemyPath (a Path2D) from start to finish.
## The enemy is instantiated as a child of a PathFollow2D, which in turn is a
## child of the Path2D. Each physics frame the PathFollow2D advances along the
## curve, which moves this node along the path. It has health and can be
## damaged by towers.

signal died(reward_amount: int)

@export var speed: float = 100.0
# HP is low enough that the starting two towers (100$ / 50$ each) can kill
# enemies, so the money loop is playable from the start.
@export var health: int = 4
@export var reward: int = 10

func _ready() -> void:
	print("BasicEnemy spawned at ", global_position)

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
	if health <= 0:
		return
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	died.emit(reward)
	if is_instance_valid(get_parent()) and get_parent() is PathFollow2D:
		get_parent().queue_free()
	else:
		queue_free()

## Called when the enemy completes the path. Frees the PathFollow2D (and this
## node as its child) so nothing lingers in the scene.
func _reach_end() -> void:
	print("BasicEnemy reached end, freeing")
	if is_instance_valid(get_parent()) and get_parent() is PathFollow2D:
		get_parent().queue_free()
