extends Node

## Geometry/layout test for the redesigned HUD. Verifies all panels stay inside
## the viewport, occupy the right regions (top bar / right dock / bottom dock),
## flip correctly when a tower sits near the dock, and that the mobile layout
## switches to a 4-column bottom dock. Prints PASS/FAIL and quits with an exit
## code. Run windowed (not --headless) so resize/layout matches real rendering.

const GAME := preload("res://scenes/game.tscn")
const THEME: Theme = preload("res://ui_theme.tres")

var _failures := 0
var game: Node

func _ready() -> void:
	game = GAME.instantiate()
	add_child(game)
	await get_tree().create_timer(0.5).timeout
	_run_checks()

func _check(cond: bool, label: String) -> void:
	if cond:
		print("  [PASS] %s" % label)
	else:
		_failures += 1
		printerr("  [FAIL] %s" % label)

func _in_vp(node: Control, vp: Vector2, label: String) -> void:
	var pos: Vector2 = node.global_position
	var sz: Vector2 = node.size
	_check(pos.x >= -1.0 and pos.y >= -1.0
		and pos.x + sz.x <= vp.x + 1.0 and pos.y + sz.y <= vp.y + 1.0,
		"%s inside viewport (rect %s in %s)" % [label, Rect2(pos, sz), vp])

func _run_checks() -> void:
	var vp := get_viewport().get_visible_rect().size
	print("== Desktop layout (%s) ==" % vp)
	_check(game._layout_metrics()["mobile"] == false, "default window is desktop layout")

	var top: Control = game.get_node("UI/TopBar")
	_check(top.offset_bottom <= 62.0, "top bar strip height <= 62 (got %.1f)" % top.offset_bottom)
	_check(top.position.x >= -1.0 and top.size.x >= vp.x - 2.0,
		"top bar spans full width (size.x=%.1f vp.x=%.1f)" % [top.size.x, vp.x])

	var dock: Control = game.get_node("UI/TowerDock")
	var grid: GridContainer = game.get_node("UI/TowerDock/DockBox/SlotGrid")
	_check(dock.position.x >= vp.x - 116.0, "desktop dock on the right side (x=%.1f)" % dock.position.x)
	_check(dock.position.x + dock.size.x <= vp.x + 1.0, "dock right edge inside viewport")
	_check(grid.columns == 1, "desktop dock uses 1 column")
	_check(dock.get_node("DockBox/ShopHeader").visible, "shop header visible on desktop")

	print("== ArmedInfo geometry ==")
	game._set_tower_type(0)
	await _two_frames()
	var armed: Control = game.get_node("UI/ArmedInfo")
	_check(armed.visible, "ArmedInfo visible when armed")
	_in_vp(armed, vp, "ArmedInfo")
	var armed_right: float = armed.global_position.x + armed.size.x
	_check(armed_right <= dock.position.x + 2.0,
		"ArmedInfo does not overlap the dock (right=%.1f dock.x=%.1f)" % [armed_right, dock.position.x])
	game._disarm_tower_type()
	await _two_frames()

	print("== Placed tower -> TowerInfo ==")
	var tile := _find_sand_tile()
	_check(tile != Vector2i(-1, -1), "map has a sand tile to place on")
	game._set_tower_type(0)
	if tile != Vector2i(-1, -1):
		var center := Vector2(tile.x * game.TILE_SIZE + game.TILE_SIZE / 2.0,
			tile.y * game.TILE_SIZE + game.TILE_SIZE / 2.0)
		var placed: bool = game._try_place_tower(center)
		_check(placed, "tower actually placed on sand tile")
		if placed:
			var tower: Node2D = game._towers[tile]
			game._select_tower(tower)
			await _two_frames()
			_check(game._selected_tower == tower, "tower is selected")

			var info: Control = game.get_node("UI/TowerInfo")
			_check(info.visible, "TowerInfo visible when tower selected")
			_in_vp(info, vp, "TowerInfo")
			var info_right: float = info.global_position.x + info.size.x
			_check(info_right <= dock.position.x + 2.0,
				"TowerInfo does not overlap the dock (right=%.1f dock.x=%.1f)" % [info_right, dock.position.x])
			_check(info.get_node("TowerInfoBox/InfoHeader/InfoHeaderText/LevelLabel").text == "LV1 · ELIGE",
				"LevelLabel reads 'LV1 · ELIGE' (got '%s')" % info.get_node("TowerInfoBox/InfoHeader/InfoHeaderText/LevelLabel").text)
			var branch_row: Control = info.get_node("TowerInfoBox/BranchRow")
			_check(branch_row.visible, "BranchRow visible at level 1")
			var ba: Button = branch_row.get_node("BranchAButton")
			_check(ba.text.contains("+$"), "Branch A shows specialization + cost (got '%s')" % ba.text)
			var sell: Button = info.get_node("TowerInfoBox/ActionRow/SellButton")
			_check(sell.text.contains("SELL"), "Sell button labelled (got '%s')" % sell.text)
			var sprite: TextureRect = info.get_node("TowerInfoBox/InfoHeader/TowerSprite")
			_check(sprite.texture != null, "TowerInfo header sprite mirrors the tower")

			print("== TowerInfo near dock edge (flip) ==")
			var far_tile := _find_sand_tile(false)
			if far_tile != Vector2i(-1, -1) and far_tile != tile:
				var c2 := Vector2(far_tile.x * game.TILE_SIZE + game.TILE_SIZE / 2.0,
					far_tile.y * game.TILE_SIZE + game.TILE_SIZE / 2.0)
				_if_placed_select(c2)
				await _two_frames()
				_in_vp(info, vp, "TowerInfo (far tile)")

	print("== Tooltip bounds ==")
	var tooltip: Control = game.get_node("UI/Tooltip")
	tooltip.delay = 0.0
	tooltip.show_stats("Basic Tower", [
		{"icon": null, "label": "Damage", "value": "1"},
		{"icon": null, "label": "Cost", "value": "$50"},
	], "Descripción de prueba.")
	await _two_frames()
	var tpanel: Control = null
	for child in tooltip.get_children():
		if child is PanelContainer:
			tpanel = child
			break
	_in_vp(tpanel, vp, "Tooltip panel")
	_check(tooltip.size.x <= 10.0, "Tooltip root is content-sized, not full-rect (got %.1f)" % tooltip.size.x)

	print("== Mobile layout ==")
	get_window().size = Vector2i(820, 1180)
	await get_tree().create_timer(0.5).timeout
	vp = get_viewport().get_visible_rect().size
	_check(game._layout_metrics()["mobile"] == true, "narrow window switches to mobile layout")
	_check(grid.columns == 4, "mobile dock uses 4 columns")
	_check(not dock.get_node("DockBox/ShopHeader").visible, "shop header hidden on mobile")
	var dock_bottom: float = dock.global_position.y + dock.size.y
	_check(dock.global_position.y >= vp.y - 110.0 and dock_bottom <= vp.y + 1.0,
		"mobile dock sits on the bottom edge (y=%.1f bottom=%.1f vp.y=%.1f)" % [dock.global_position.y, dock_bottom, vp.y])
	if is_instance_valid(game._selected_tower):
		_in_vp(game.get_node("UI/TowerInfo"), vp, "TowerInfo (mobile)")

	if _failures == 0:
		print("ALL HUD LAYOUT CHECKS PASSED")
	else:
		print("%d HUD LAYOUT CHECKS FAILED" % _failures)
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(1 if _failures > 0 else 0)

func _two_frames() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func _find_sand_tile(prefer_left: bool = true) -> Vector2i:
	for x in range(game.MAP_COLS):
		var cx: int = x if prefer_left else game.MAP_COLS - 1 - x
		for y in range(game.MAP_ROWS):
			if game.get_node("Map").get_cell_atlas_coords(Vector2i(cx, y)) == game.ATLAS_SAND:
				return Vector2i(cx, y)
	return Vector2i(-1, -1)

func _if_placed_select(center: Vector2) -> void:
	game._set_tower_type(0)
	var placed: bool = game._try_place_tower(center)
	if placed:
		var tile := Vector2i(floori(center.x / game.TILE_SIZE), floori(center.y / game.TILE_SIZE))
		game._select_tower(game._towers[tile])