extends Control
class_name Tooltip
## Reusable tooltip: a themed panel (TooltipPanel) that shows a title + stat rows
## with inline icons, or a plain text block. Follows the mouse cursor
## (clamped to viewport). Call show_stats(title, rows, footer) or show_for(text)
## on mouse_entered, hide_tooltip() on mouse_exited.

const MAX_WIDTH := 260
const PANEL_PADDING := 14
const ROW_SPACING := 8
const ICON_SIZE := 20

@export var delay: float = 0.35
@export var margin: int = 14

var _timer: float = 0.0
var _pending: Callable
var _visible: bool = false
var _panel: PanelContainer
var _box: VBoxContainer
var _title: Label
var _divider: PanelContainer
var _footer: Label

func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"TooltipPanel"
	_panel.mouse_filter = MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size = Vector2(MAX_WIDTH, 0)
	add_child(_panel)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", ROW_SPACING)
	_box.add_theme_constant_override("margin_left", PANEL_PADDING)
	_box.add_theme_constant_override("margin_top", PANEL_PADDING)
	_box.add_theme_constant_override("margin_right", PANEL_PADDING)
	_box.add_theme_constant_override("margin_bottom", PANEL_PADDING)
	_panel.add_child(_box)

	_title = Label.new()
	_title.theme_type_variation = &"tooltip_title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.visible = false
	_box.add_child(_title)

	_divider = PanelContainer.new()
	_divider.theme_type_variation = &"sb_divider"
	_divider.custom_minimum_size = Vector2(0, 1)
	_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_divider.visible = false
	_box.add_child(_divider)

	_footer = Label.new()
	_footer.theme_type_variation = &"tooltip_desc"
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
	_timer = 0.0
	_clear_content()
	if _visible:
		_visible = false
		visible = false

func _clear_content() -> void:
	for child in _box.get_children():
		if child == _title or child == _divider or child == _footer:
			continue
		child.queue_free()
	_title.text = ""
	_title.visible = false
	_divider.visible = false
	_footer.text = ""
	_footer.visible = false

func _show_now() -> void:
	if not _pending.is_valid():
		return
	_pending.call()
	_visible = true
	visible = true
	call_deferred("_follow_mouse")

func _build_plain(text: String) -> void:
	_clear_content()
	var label := Label.new()
	label.theme_type_variation = &"tooltip_desc"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(MAX_WIDTH - PANEL_PADDING * 2, 0)
	_box.add_child(label)
	label.text = text
	await get_tree().process_frame
	_follow_mouse()

func _build_stats(title: String, rows: Array, footer: String = "") -> void:
	_clear_content()
	_title.text = title
	_title.visible = true
	_divider.visible = true

	for row in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = MOUSE_FILTER_IGNORE
		if row.has("icon") and row.icon != null:
			icon.texture = row.icon
		line.add_child(icon)

		var label := Label.new()
		label.theme_type_variation = &"tooltip_stat_label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = row.label
		line.add_child(label)

		var value := Label.new()
		value.theme_type_variation = &"tooltip_stat_value"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.text = row.value
		line.add_child(value)

		_box.add_child(line)

	if footer != "":
		_footer.text = footer
		_footer.visible = true

	await get_tree().process_frame
	_follow_mouse()

func _follow_mouse() -> void:
	var vp_size := get_viewport_rect().size
	var pos := get_global_mouse_position() + Vector2(margin, margin)
	var sz := _panel.get_size()
	pos.x = clampf(pos.x, 0, vp_size.x - sz.x - margin)
	pos.y = clampf(pos.y, 0, vp_size.y - sz.y - margin)
	position = pos