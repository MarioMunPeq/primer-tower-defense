extends Node2D
## Basic enemy that follows the EnemyPath (a Path2D) from start to finish.
## The enemy is instantiated as a child of a PathFollow2D, which in turn is a
## child of the Path2D. Each physics frame the PathFollow2D advances along the
## curve, which moves this node along the path.

@export var speed: float = 100.0

func _ready() -> void:
	print("BasicEnemy spawned at ", global_position)

func _physics_process(delta: float) -> void:
	var follow := get_parent() as PathFollow2D
	if follow == null:
		return

	follow.progress += speed * delta

	if follow.progress_ratio >= 1.0:
		_reach_end()

## Called when the enemy completes the path. Frees the PathFollow2D (and this
## node as its child) so nothing lingers in the scene.
func _reach_end() -> void:
	print("BasicEnemy reached end, freeing")
	get_parent().queue_free()
