extends Control
## Main menu: first scene loaded. Buttons -> start game, options, quit.

@onready var _play_btn: Button = $CenterContainer/VBox/PlayButton
@onready var _options_btn: Button = $CenterContainer/VBox/OptionsButton
@onready var _quit_btn: Button = $CenterContainer/VBox/QuitButton

func _ready() -> void:
	_play_btn.pressed.connect(_on_play_pressed)
	_options_btn.pressed.connect(_on_options_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)
	# Focus Play for gamepad/keyboard navigation
	_play_btn.grab_focus()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_options_pressed() -> void:
	# TODO: open options overlay
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()