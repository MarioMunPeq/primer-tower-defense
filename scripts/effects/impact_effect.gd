extends Node2D
## Simple impact effect: brief expanding ring at impact position.
## Self-destructs after animation completes.

var _tween: Tween = null

func _ready() -> void:
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.2)
	_tween.finished.connect(_on_finished)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.9, 0.4, 0.8), false, 2.0)

func _on_finished() -> void:
	queue_free()