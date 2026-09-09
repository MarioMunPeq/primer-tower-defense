extends Control
## Pause menu overlay: Resume, Restart, Main Menu, Volume slider.

signal resume_requested
signal restart_requested
signal main_menu_requested
signal volume_changed(bus: int, volume_db: float)

@onready var _resume_btn: Button = $Panel/VBox/ResumeButton
@onready var _restart_btn: Button = $Panel/VBox/RestartButton
@onready var _menu_btn: Button = $Panel/VBox/MenuButton
@onready var _volume_slider: HSlider = $Panel/VBox/VolumeBox/VolumeSlider
@onready var _volume_label: Label = $Panel/VBox/VolumeBox/VolumeLabel

func _ready() -> void:
	_resume_btn.pressed.connect(_on_resume)
	_restart_btn.pressed.connect(_on_restart)
	_menu_btn.pressed.connect(_on_main_menu)
	_volume_slider.value_changed.connect(_on_volume_changed)
	# Load current master volume (bus 0)
	_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0)) * 100
	_update_volume_label()

func _on_resume() -> void:
	resume_requested.emit()
	queue_free()

func _on_restart() -> void:
	restart_requested.emit()
	queue_free()

func _on_main_menu() -> void:
	main_menu_requested.emit()
	queue_free()

func _on_volume_changed(value: float) -> void:
	var db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, db)
	_update_volume_label()
	volume_changed.emit(0, db)

func _update_volume_label() -> void:
	_volume_label.text = "Volumen: %d%%" % _volume_slider.value
