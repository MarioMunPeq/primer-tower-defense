extends Label
## A single pooled floating damage number. Animates upward while fading, then
## tells its pool it can be reused (avoids allocating/freeing nodes per hit).

signal recycled(node: Label)

var _tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func spawn(amount: int, world_pos: Vector2) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	text = str(amount)
	position = world_pos - Vector2(10, 8)
	visible = true
	modulate = Color(1.0, 0.96, 0.7, 1.0)
	scale = Vector2(1.15, 1.15)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position:y", world_pos.y - 34.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.3)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25)
	tw.chain().tween_callback(_on_done)
	_tween = tw

func _on_done() -> void:
	if not visible:
		return
	recycled.emit(self)