extends Node2D
## Draws a single translucent range circle that can follow the cursor (preview)
## or mark a placed tower's range. One persistent node redrawn on demand, so no
## nodes are created per frame. The radius comes from the caller (the real
## BasicTower.range value) so it always matches the actual attack range.

var _center := Vector2(INF, INF)
var _radius := 0.0
var _color := Color.WHITE

## Activates the circle. radius must be the real tower range in world px.
func show_range(center: Vector2, radius: float, color: Color) -> void:
	_center = center
	_radius = radius
	_color = color
	queue_redraw()

func hide_range() -> void:
	_center = Vector2(INF, INF)
	queue_redraw()

func _draw() -> void:
	if _center == Vector2(INF, INF) or _radius <= 0.0:
		return
	var fill := Color(_color.r, _color.g, _color.b, 0.12)
	draw_circle(_center, _radius, fill)
	draw_arc(_center, _radius, 0.0, TAU, 96, _color, 2.0)
