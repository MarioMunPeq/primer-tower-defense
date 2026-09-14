extends Control
class_name Tooltip
## Reusable tooltip: a themed panel (tooltip_panel) that shows a title + stat rows
## with colored icon chips, or a plain text block. Follows the mouse cursor
## (clamped to viewport). Call show_stats(title, rows, footer) or show_for(text)
## on mouse_entered, hide_tooltip() on mouse_exited.

const ICON_CHIP_SIZE := 32
const STAT_ICON_SIZE := 18
const ROW_SPACING := 11
const PANEL_PADDING := 16

@export var delay: float = 0.4
@export var margin: int = 16
@export var max_width: int = 280

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
	_panel.theme_type_variation = &"tooltip_panel"
	_panel.mouse_filter = MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size = Vector2(max_width, 0)
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
	_title.add_theme_font_size_override("font_size", 24)
	_title.visible = false
	_box.add_child(_title)

	_divider = PanelContainer.new()
	_divider.theme_type_variation = &"tooltip_divider"
	_divider.custom_minimum_size = Vector2(0, 1)
	_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_divider.visible = false
	_box.add_child(_divider)

	_footer = Label.new()
	_footer.theme_type_variation = &"tooltip_desc"
	_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer.add_theme_font_size_override("font_size", 13)
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

## Stat tooltip: title + rows of [icon_chip][label+value] + optional footer text.
## Each row is a Dictionary: { "icon": Texture2D, "label": String, "value": String, "chip_type": String }.
## chip_type: "damage", "range", "speed", "freeze", "slow", "splash", "pierce", "cost", or ""
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
	label.custom_minimum_size = Vector2(max_width - PANEL_PADDING * 2, 0)
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

		var chip := _create_icon_chip(row.icon, row.get("chip_type", ""))
		line.add_child(chip)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)

		var label := Label.new()
		label.theme_type_variation = &"tooltip_stat_label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", 14)
		label.text = row.label
		vbox.add_child(label)

		var value := Label.new()
		value.theme_type_variation = &"tooltip_stat_value"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		value.add_theme_font_size_override("font_size", 17)
		value.text = row.value
		vbox.add_child(value)

		line.add_child(vbox)
		_box.add_child(line)

	if footer != "":
		_footer.text = footer
		_footer.visible = true

	await get_tree().process_frame
	_follow_mouse()

func _create_icon_chip(icon_tex: Texture2D, chip_type: String) -> Control:
	# Cost row: no chip, just the icon
	if chip_type == "cost" or chip_type == "":
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(STAT_ICON_SIZE, STAT_ICON_SIZE)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = MOUSE_FILTER_IGNORE
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if icon_tex != null:
			icon.texture = icon_tex
		return icon

	var chip := PanelContainer.new()
	var chip_theme := "tooltip_chip_damage"
	match chip_type:
		"damage": chip_theme = "tooltip_chip_damage"
		"range": chip_theme = "tooltip_chip_range"
		"speed": chip_theme = "tooltip_chip_speed"
		"freeze": chip_theme = "tooltip_chip_freeze"
		"slow": chip_theme = "tooltip_chip_slow"
		"splash": chip_theme = "tooltip_chip_splash"
		"pierce": chip_theme = "tooltip_chip_pierce"
	chip.theme_type_variation = chip_theme
	chip.custom_minimum_size = Vector2(ICON_CHIP_SIZE, ICON_CHIP_SIZE)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = MOUSE_FILTER_IGNORE

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(STAT_ICON_SIZE, STAT_ICON_SIZE)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	if icon_tex != null:
		icon.texture = icon_tex
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = (ICON_CHIP_SIZE - STAT_ICON_SIZE) / 2
	icon.offset_top = (ICON_CHIP_SIZE - STAT_ICON_SIZE) / 2
	icon.offset_right = (ICON_CHIP_SIZE - STAT_ICON_SIZE) / 2
	icon.offset_bottom = (ICON_CHIP_SIZE - STAT_ICON_SIZE) / 2
	chip.add_child(icon)

	return chip

func _follow_mouse() -> void:
	var vp_size := get_viewport_rect().size
	var pos := get_global_mouse_position() + Vector2(margin, margin)
	var sz := _panel.get_size()
	pos.x = clampf(pos.x, 0, vp_size.x - sz.x - margin)
	pos.y = clampf(pos.y, 0, vp_size.y - sz.y - margin)
	position = pos