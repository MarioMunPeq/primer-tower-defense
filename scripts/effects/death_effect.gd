extends GPUParticles2D
## One-shot death burst. The enemy passes its palette through setup(); particles
## start emitting on _ready and the node frees itself shortly after the burst.

var _freeing := false

func _ready() -> void:
	one_shot = true
	emitting = true
	get_tree().create_timer(0.8, true).timeout.connect(_on_timer)

## Sets the per-type colour ramp (start -> end) right after instantiation.
func setup(start_color: Color, end_color: Color) -> void:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	ramp.colors = PackedColorArray([start_color, start_color, end_color])
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	var mat: ParticleProcessMaterial = process_material as ParticleProcessMaterial
	if mat != null:
		mat.color_ramp = tex

func _on_timer() -> void:
	if _freeing:
		return
	_freeing = true
	queue_free()