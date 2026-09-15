extends Node

## Headless flow check for pause/resume and speed buttons in the new HUD.

const GAME := preload("res://scenes/game.tscn")

var _failures := 0

func _ready() -> void:
	var game: Node = GAME.instantiate()
	add_child(game)
	await get_tree().create_timer(0.4).timeout
	_run(game)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("  [PASS] %s" % label)
	else:
		_failures += 1
		printerr("  [FAIL] %s" % label)

func _run(game: Node) -> void:
	var pause: Button = game.get_node("UI/TopBar/TopBarBox/SpeedGroup/PauseButton")

	print("== Speed switching ==")
	game._set_speed(3)
	var sp3: Button = game.get_node("UI/TopBar/TopBarBox/SpeedGroup/Speed3Button")
	_check(sp3.theme_type_variation == &"SpeedBtnActive" and Engine.time_scale == 3.0,
		"speed 3x active + Engine.time_scale=3")
	game._set_speed(1)
	_check(game.get_node("UI/TopBar/TopBarBox/SpeedGroup/Speed1Button").theme_type_variation == &"SpeedBtnActive"
		and Engine.time_scale == 1.0, "speed 1x restores")

	print("== Pause toggle ==")
	game._on_pause_pressed()
	await get_tree().process_frame
	var menu: Control = game.get_node("UI/PauseMenu")
	_check(menu != null, "PauseMenu added under UI")
	_check(get_tree().paused, "tree is paused")
	_check(pause.theme_type_variation == &"SpeedBtnActive", "pause button shows active state")
	if menu != null:
		var resume: Button = menu.get_node("Panel/VBox/ResumeButton")
		_check(resume != null and resume.text == "REANUDAR",
			"Resume button labelled REANUDAR (got '%s')" % (resume.text if resume else "N/A"))
		_check(menu.get_node("Panel/VBox/Title").text == "PAUSA", "Pause title reads PAUSA")
		var slider: HSlider = menu.get_node("Panel/VBox/VolumeBox/VolumeSlider")
		_check(slider != null, "volume slider present")
	game._on_pause_resume()
	await get_tree().process_frame
	_check(not get_tree().paused, "tree resumes")
	_check(pause.theme_type_variation == &"SpeedBtn", "pause button back to normal state")

	if _failures == 0:
		print("ALL PAUSE CHECKS PASSED")
	else:
		print("%d PAUSE CHECKS FAILED" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)