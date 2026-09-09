extends Control
## Main menu: first scene loaded. Buttons -> start game, options, quit.

const _HOVER_SCALE := 1.03

@onready var _play_btn: Button = $CenterContainer/VBox/PlayButton
@onready var _options_btn: Button = $CenterContainer/VBox/OptionsButton
@onready var _quit_btn: Button = $CenterContainer/VBox/QuitButton

var _btn_tweens: Dictionary = {}

func _ready() -> void:
	_play_btn.pressed.connect(_on_play_pressed)
	_options_btn.pressed.connect(_on_options_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)
	for btn in [_play_btn, _options_btn, _quit_btn]:
		btn.mouse_entered.connect(_tween_btn_scale.bind(btn, _HOVER_SCALE))
		btn.mouse_exited.connect(_tween_btn_scale.bind(btn, 1.0))
	# Focus Play for gamepad/keyboard navigation
	_play_btn.grab_focus()

func _tween_btn_scale(btn: Button, target: float) -> void:
	var old: Tween = _btn_tweens.get(btn)
	if old != null and old.is_valid():
		old.kill()
	btn.pivot_offset = btn.size * 0.5
	var tw := create_tween()
	_btn_tweens[btn] = tw
	tw.tween_property(btn, "scale", Vector2(target, target), 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/options_menu.tscn")

func _on_quit_pressed() -> void:
	if OS.has_feature("web"):
		return
	get_tree().quit()