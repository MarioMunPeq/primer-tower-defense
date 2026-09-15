extends Node

## Captures the main menu and the options menu for visual review.
## Run WITHOUT --headless.

const OUT_DIR := "C:/Users/Mario/AppData/Local/Temp/opencode/hud"

var _current: Node

func _capture(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	img.save_png(path)
	print("saved %s" % path)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_current = preload("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(_current)
	await get_tree().create_timer(0.6).timeout
	await _capture("main_menu")
	_current.queue_free()
	await get_tree().process_frame

	_current = preload("res://scenes/ui/options_menu.tscn").instantiate()
	add_child(_current)
	await get_tree().create_timer(0.6).timeout
	await _capture("options_menu")
	get_tree().quit(0)