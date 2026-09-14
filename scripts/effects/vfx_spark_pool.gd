extends Node2D
## Reusable spark-burst pool. Recycles impact_particles nodes on a timer so a
## burst can never accumulate as a leaked, invisible emitter (GPUParticles2D
## `finished` is unreliable here, so self-freeing through that signal was the
## cause of the leak). Also removes per-event instancing churn.

const SPARKS := preload("res://scenes/effects/impact_particles.tscn")
const POOL_SIZE := 32
const BURST_KEEP := 0.55  # seconds a spark is visible before recycling

var _free: Array = []
var _busy: Array = []

func _ready() -> void:
	for i in POOL_SIZE:
		var p: GPUParticles2D = SPARKS.instantiate()
		p.emitting = false
		p.visible = false
		add_child(p)
		_free.append(p)

## Plays a spark burst at the given world position, reusing a pooled node.
func spawn(center: Vector2) -> void:
	var p: GPUParticles2D = null
	if not _free.is_empty():
		p = _free.pop_back()
	else:
		p = SPARKS.instantiate()
		add_child(p)
	_busy.append(p)
	p.global_position = center
	p.visible = true
	p.restart()
	get_tree().create_timer(BURST_KEEP, true).timeout.connect(_recycle.bind(p))

func _recycle(p: GPUParticles2D) -> void:
	if not is_instance_valid(p):
		return
	p.emitting = false
	p.visible = false
	_busy.erase(p)
	_free.append(p)