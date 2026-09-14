extends GPUParticles2D
## One-shot spark burst at projectile impact points.
## Frees itself automatically when the burst finishes.

func _ready() -> void:
	finished.connect(queue_free)