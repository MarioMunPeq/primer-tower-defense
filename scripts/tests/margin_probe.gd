extends Node

func _ready() -> void:
	await get_tree().process_frame
	var host := PanelContainer.new()
	host.set_anchors_preset(Control.PRESET_CENTER)
	add_child(host)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("margin_left", 12)
	box.add_theme_constant_override("margin_top", 10)
	box.add_theme_constant_override("margin_right", 12)
	box.add_theme_constant_override("margin_bottom", 10)
	host.add_child(box)
	var one := ColorRect.new()
	one.custom_minimum_size = Vector2(80, 20)
	box.add_child(one)
	await get_tree().process_frame
	print("HOST rect=", host.get_global_rect(), " size=", host.size)
	print("BOX  rect=", box.get_global_rect(), " size=", box.size)
	print("ONE  rect=", one.get_global_rect())
	print("box margin_top =", box.get_theme_constant("margin_top"),
		" margin_left =", box.get_theme_constant("margin_left"))
	print("HOST min =", host.get_combined_minimum_size())
	get_tree().quit(0)