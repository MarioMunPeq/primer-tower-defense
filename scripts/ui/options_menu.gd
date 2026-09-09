extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var _back_btn: Button = %BackButton
@onready var _fullscreen_toggle: Button = %FullscreenToggle
@onready var _sell_toggle: Button = %SellToggle
@onready var _quality_group: HBoxContainer = %QualityGroup
@onready var _speed_group: HBoxContainer = %SpeedGroup

func _ready() -> void:
	_fullscreen_toggle.button_pressed = Settings.fullscreen
	_sell_toggle.button_pressed = Settings.sell_confirm
	_refresh_toggle(_fullscreen_toggle)
	_refresh_toggle(_sell_toggle)
	for i in _quality_group.get_child_count():
		_refresh_segment(_quality_group.get_child(i), i == Settings.quality)
	for i in _speed_group.get_child_count():
		_refresh_segment(_speed_group.get_child(i), int(_speed_group.get_child(i).name.right(-1)) == Settings.default_speed)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_sell_toggle.toggled.connect(_on_sell_toggled)
	_quality_group.get_child(0).pressed.connect(_on_quality_selected.bind(0))
	_quality_group.get_child(1).pressed.connect(_on_quality_selected.bind(1))
	_speed_group.get_child(0).pressed.connect(_on_speed_selected.bind(1))
	_speed_group.get_child(1).pressed.connect(_on_speed_selected.bind(2))
	_speed_group.get_child(2).pressed.connect(_on_speed_selected.bind(3))
	_back_btn.pressed.connect(_on_back_pressed)

func _refresh_toggle(btn: Button) -> void:
	btn.text = "ON" if btn.button_pressed else "OFF"
	btn.theme_type_variation = "speed_active" if btn.button_pressed else "speed"

func _refresh_segment(btn: Button, selected: bool) -> void:
	btn.button_pressed = selected
	btn.theme_type_variation = "speed_active" if selected else "speed"

func _on_fullscreen_toggled(_pressed: bool) -> void:
	_refresh_toggle(_fullscreen_toggle)
	Settings.set_fullscreen(_fullscreen_toggle.button_pressed)

func _on_sell_toggled(_pressed: bool) -> void:
	_refresh_toggle(_sell_toggle)
	Settings.set_sell_confirm(_sell_toggle.button_pressed)

func _on_quality_selected(idx: int) -> void:
	for i in _quality_group.get_child_count():
		_refresh_segment(_quality_group.get_child(i), i == idx)
	Settings.set_quality(idx)

func _on_speed_selected(multiplier: int) -> void:
	for i in _speed_group.get_child_count():
		_refresh_segment(_speed_group.get_child(i), int(_speed_group.get_child(i).name.right(-1)) == multiplier)
	Settings.set_default_speed(multiplier)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)