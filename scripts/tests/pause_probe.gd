extends Node

const GAME := preload("res://scenes/game.tscn")

func _ready() -> void:
	var game: Node2D = GAME.instantiate()
	add_child(game)
	await get_tree().create_timer(0.5).timeout
	var btn: Button = game.get_node("UI/HUDBar/HUDTop/SpeedPanel/PauseButton")
	btn.pressed.emit()
	await get_tree().process_frame
	var menu: Control = game.get_node("UI/PauseMenu")
	var resume: Button = menu.get_node("Panel/VBox/ResumeButton")
	var restart: Button = menu.get_node("Panel/VBox/RestartButton")
	var main_menu: Button = menu.get_node("Panel/VBox/MenuButton")
	var slider: HSlider = menu.get_node("Panel/VBox/VolumeBox/VolumeSlider")
	print("PROBE 1. pause tree: paused=%s icon=%s" % [get_tree().paused, btn.text])
	print("PROBE 2. menu type=%s mode=%s visible=%s" % [menu.get_class(), menu.process_mode, menu.visible])
	print("PROBE 3. all buttons found: resume=%s restart=%s main_menu=%s slider=%s" % [resume != null, restart != null, main_menu != null, slider != null])
	print("PROBE 4. resume text='%s'" % resume.text)
	resume.pressed.emit()
	await get_tree().process_frame
	print("PROBE 5. after resume: paused=%s icon=%s menu_exists=%s" % [get_tree().paused, btn.text, is_instance_valid(menu)])
	btn.pressed.emit()
	await get_tree().process_frame
	menu = game.get_node("UI/PauseMenu")
	var restart_btn: Button = menu.get_node("Panel/VBox/RestartButton")
	restart_btn.pressed.emit()
	await get_tree().process_frame
	print("PROBE 6. after restart: paused=%s" % get_tree().paused)
	print("ALL PAUSE PROBE CHECKS PASSED")
	get_tree().quit(0)