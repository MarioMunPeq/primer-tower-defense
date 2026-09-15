extends Node

## Windowed screenshot capture for the redesigned HUD. Runs the real game
## scene, captures: (1) idle desktop HUD, (2) armed Basic + tooltip shown,
## (3) idle mobile layout. PNGs are written to an absolute temp path and the
## window quits when done. Run WITHOUT --headless.

const GAME := preload("res://scenes/game.tscn")
const OUT_DIR := "C:/Users/Mario/AppData/Local/Temp/opencode/hud"

var game: Node

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	game = GAME.instantiate()
	add_child(game)
	get_tree().create_timer(0.6).timeout.connect(_shot_idle)

func _capture(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	img.save_png(path)
	print("saved %s" % path)

func _shot_idle() -> void:
	await _capture("desktop_idle")
	_arm_and_tooltip()

func _arm_and_tooltip() -> void:
	var basic: Button = game.get_node("UI/TowerDock/DockBox/SlotGrid/BasicSlot")
	basic.emit_signal("pressed")
	var tooltip: Control = game.get_node("UI/Tooltip")
	tooltip.delay = 0.0
	game._show_tower_card_tooltip(0)
	await get_tree().create_timer(0.4).timeout
	await _capture("desktop_armed_tooltip")
	_speed_high()

func _speed_high() -> void:
	var sp3: Button = game.get_node("UI/TopBar/TopBarBox/SpeedGroup/Speed3Button")
	sp3.emit_signal("pressed")
	await _capture("desktop_speed3")
	_tower_card()

func _tower_card() -> void:
	game._disarm_tower_type()
	for x in range(game.MAP_COLS):
		for y in range(game.MAP_ROWS):
			if game.get_node("Map").get_cell_atlas_coords(Vector2i(x, y)) == game.ATLAS_SAND:
				var center := Vector2(x * game.TILE_SIZE + game.TILE_SIZE / 2.0,
					y * game.TILE_SIZE + game.TILE_SIZE / 2.0)
				game._set_tower_type(0)
				if game._try_place_tower(center):
					var tile := Vector2i(x, y)
					game._select_tower(game._towers[tile])
					await _capture("desktop_tower_selected")
					break
		if game._selected_tower != null:
			break
	_mobile()

func _mobile() -> void:
	get_window().size = Vector2i(820, 1180)
	await get_tree().create_timer(0.4).timeout
	game._deselect_tower()
	await _capture("mobile_idle")
	get_tree().quit(0)