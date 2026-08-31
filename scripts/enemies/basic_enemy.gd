extends Node2D
## Basic enemy that follows the EnemyPath (a Path2D) from start to finish.
## The enemy is instantiated as a child of a PathFollow2D, which in turn is a
## child of the Path2D. Each physics frame the PathFollow2D advances along the
## curve, which moves this node along the path. It has health and can be
## damaged by towers.

@export var speed: float = 100.0
@export var health: int = 10

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
## frees its PathFollow2D (and this node as its child).
func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	if not is_instance_valid(get_parent()):
		return
	if get_parent() is PathFollow2D:
		get_parent().queue_free()
	else:
		queue_free()

## Called when the enemy completes the path. Frees the PathFollow2D (and this
## node as its child) so nothing lingers in the scene.
func _reach_end() -> void:
	print("BasicEnemy reached end, freeing")
	if is_instance_valid(get_parent()) and get_parent() is PathFollow2D:
		get_parent().queue_free()
