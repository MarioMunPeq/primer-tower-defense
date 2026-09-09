extends Control
class_name Tooltip
## Reusable tooltip: shows a text block after a short hover delay. Follows the
## mouse cursor (clamped to viewport). Call show_for(text) on mouse_entered,
## hide_tooltip() on mouse_exited. Can be instanced multiple times or used as a singleton.

@export var delay: float = 0.4
@export var margin: int = 16
@export var max_width: int = 280

var _timer: float = 0.0
var _pending_text: String = ""
var _visible: bool = false
var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(max_width, 0)
	_label.add_theme_constant_override("line_separation", 4)
	add_child(_label)
	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false

func _process(delta: float) -> void:
	if _pending_text != "" and not _visible:
		_timer += delta
		if _timer >= delay:
			_show_now()

func show_for(text: String) -> void:
	_pending_text = text
	_timer = 0.0

func hide_tooltip() -> void:
	_pending_text = ""
	if _visible:
		_visible = false
		visible = false

func _show_now() -> void:
	if _pending_text == "":
		return
	_label.text = _pending_text
	_visible = true
	visible = true
	# Force layout update so label size is correct before positioning
	# Using call_deferred to ensure layout is processed after text is set
	call_deferred("_follow_mouse")

func _follow_mouse() -> void:
	var vp_size := get_viewport_rect().size
	var pos := get_global_mouse_position() + Vector2(margin, margin)
	# Clamp to viewport
	var sz := _label.get_size()
	pos.x = clampf(pos.x, 0, vp_size.x - sz.x - margin)
	pos.y = clampf(pos.y, 0, vp_size.y - sz.y - margin)
	position = pos