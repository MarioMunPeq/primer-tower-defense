extends Control
class_name Tooltip
## Reusable tooltip: a themed panel (PanelLevel1) that shows a title + stat rows
## with icons, or a plain text block. Follows the mouse cursor (clamped to
## viewport). Call show_stats(title, rows, footer) or show_for(text) on
## mouse_entered, hide_tooltip() on mouse_exited.

const STAT_ICON_SIZE := 18

@export var delay: float = 0.4
@export var margin: int = 16
@export var max_width: int = 280

var _timer: float = 0.0
var _pending: Callable
var _visible: bool = false
var _panel: PanelContainer
var _box: VBoxContainer
var _title: Label
var _footer: Label

func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"PanelLevel1"
	_panel.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_panel)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	_box.add_theme_constant_override("margin_left", 14)
	_box.add_theme_constant_override("margin_top", 10)
	_box.add_theme_constant_override("margin_right", 14)
	_box.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(_box)

	_title = Label.new()
	_title.theme_type_variation = &"title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.visible = false
	_box.add_child(_title)

	_footer = Label.new()
	_footer.theme_type_variation = &"body"
	_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer.visible = false
	_box.add_child(_footer)

	mouse_filter = MOUSE_FILTER_IGNORE
	visible = false

func _process(delta: float) -> void:
	if _pending.is_valid() and not _visible:
		_timer += delta
		if _timer >= delay:
			_show_now()

## Plain-text tooltip (e.g. enemies, brief help).
func show_for(text: String) -> void:
	_pending = _build_plain.bind(text)
	_timer = 0.0

## Stat tooltip: title + rows of [icon][label][value] + optional footer text.
## Each row is a Dictionary: { "icon": Texture2D, "label": String, "value": String }.
func show_stats(title: String, rows: Array, footer: String = "") -> void:
	_pending = _build_stats.bind(title, rows, footer)
	_timer = 0.0

func hide_tooltip() -> void:
	_pending = Callable()
	if _visible:
		_visible = false
		visible = false

func _show_now() -> void:
	if not _pending.is_valid():
		return
	_pending.call()
	_visible = true
	visible = true
	call_deferred("_follow_mouse")

func _build_plain(text: String) -> void:
	for child in _box.get_children():
		if child == _title or child == _footer:
			continue
		child.queue_free()
	_title.text = ""
	_title.visible = false
	_footer.text = ""
	_footer.visible = false
	var label := Label.new()
	label.theme_type_variation = &"body"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(max_width, 0)
	_box.add_child(label)
	label.text = text
	_box.move_child(_footer, _box.get_child_count() - 1)
	await get_tree().process_frame
	_follow_mouse()

func _build_stats(title: String, rows: Array, footer: String = "") -> void:
	for child in _box.get_children():
		if child == _title or child == _footer:
			continue
		child.queue_free()
	_title.text = title
	_title.visible = true
	for row in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(STAT_ICON_SIZE, STAT_ICON_SIZE)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = MOUSE_FILTER_IGNORE
		if row.has("icon"):
			icon.texture = row.icon
		line.add_child(icon)
		var label := Label.new()
		label.theme_type_variation = &"card_stat"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		label.text = row.label
		line.add_child(label)
		var value := Label.new()
		value.theme_type_variation = &"stat_value"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		value.text = row.value
		line.add_child(value)
		_box.add_child(line)
	if footer != "":
		_footer.text = footer
	_footer.visible = footer != ""
	_box.move_child(_footer, _box.get_child_count() - 1)
	await get_tree().process_frame
	_follow_mouse()

func _follow_mouse() -> void:
	var vp_size := get_viewport_rect().size
	var pos := get_global_mouse_position() + Vector2(margin, margin)
	var sz := _panel.get_size()
	pos.x = clampf(pos.x, 0, vp_size.x - sz.x - margin)
	pos.y = clampf(pos.y, 0, vp_size.y - sz.y - margin)
	position = pos