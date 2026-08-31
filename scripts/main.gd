extends Node2D

const TILE_SIZE := 128
const MAP_COLS := 10
const MAP_ROWS := 5

# Atlas tile coordinates (atlas_x, atlas_y) in the 128x128 map_atlas.png grid
# Extremely conservative: only row 0 confirmed to exist
enum AtlasTile {
	# Row 0
	GRASS      = 0,   # (0,0)
	ROAD_H       = 1,   # (1,0) - original road tile
}

# Atlas coordinate lookup: AtlasTile enum value -> Vector2i(atlas_x, atlas_y)
const ATLAS_COORDS: Dictionary = {
	AtlasTile.GRASS: Vector2i(0, 0),
	AtlasTile.ROAD_H: Vector2i(1, 0),
}

const ATLAS_GRASS := Vector2i(0, 0)    # GRASS
const ATLAS_ROAD_H := Vector2i(1, 0)   # ROAD_H

const BASIC_TOWER := preload("res://scenes/towers/basic_tower.tscn")
const BASIC_TOWER_SCRIPT := preload("res://scripts/towers/basic_tower.gd")
const RAPID_TOWER := preload("res://scenes/towers/rapid_tower.tscn")
const RAPID_TOWER_SCRIPT := preload("res://scripts/towers/rapid_tower.gd")
const IMPACT_EFFECT := preload("res://scenes/effects/impact_effect.tscn")

const BASE_HP_MAX := 100

## Which tower type is currently selected for placement.
## 0 = Basic Tower, 1 = Rapid Tower
var _tower_type_to_place := 0

var _towers := {}
var _hover_tile := Vector2i(-1, -1)
var _money: int = 100
var _selected_tower: Node2D = null
var _base_hp: int = BASE_HP_MAX
var _game_ended := false

## The placement-preview range comes from the currently selected tower type.
func _preview_range() -> float:
	if _tower_type_to_place == 0:
		return BASIC_TOWER_SCRIPT.RANGE
	return RAPID_TOWER_SCRIPT.RANGE

## Cost of the currently selected tower type.
func _preview_cost() -> int:
	if _tower_type_to_place == 0:
		return BASIC_TOWER_SCRIPT.COST
	return RAPID_TOWER_SCRIPT.COST

## Scene of the currently selected tower type.
func _preview_scene() -> PackedScene:
	if _tower_type_to_place == 0:
		return BASIC_TOWER
	return RAPID_TOWER

func _ready():
	_setup_tilemap()
	_paint_map()
	_setup_path()

	var towers := Node2D.new()
	towers.name = "Towers"
	add_child(towers)

	$WaveSpawner.wave_started.connect(_on_wave_started)
	$WaveSpawner.enemy_rewarded.connect(_on_enemy_rewarded)
	$WaveSpawner.enemy_reached_base.connect(_on_enemy_reached_base)
	$WaveSpawner.game_complete.connect(_on_victory)
	$WaveSpawner.setup($EnemyPath)
	$EndScreen/Center/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	
	# Connect tower selection buttons
	$UI/TowerShop/VBox/BasicButton.pressed.connect(func(): _set_tower_type(0))
	$UI/TowerShop/VBox/RapidButton.pressed.connect(func(): _set_tower_type(1))
	
	# Connect upgrade button
	$UI/TowerInfoPanel/VBox/UpgradeButton.pressed.connect(_on_upgrade_pressed)
	
	_update_money_ui()
	_update_base_ui()
	_update_tower_info_panel()
	_update_shop_ui()

func _setup_tilemap():
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source := TileSetAtlasSource.new()
	source.texture = preload("res://assets/tilesets/map_atlas.png")
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Row 0 only - confirmed from original working code
	source.create_tile(Vector2i(0, 0))   # GRASS
	source.create_tile(Vector2i(1, 0))   # ROAD_H (original road)

	ts.add_source(source, 0)
	$Map.tile_set = ts

func _atlas(tile: AtlasTile) -> Vector2i:
	return ATLAS_COORDS[tile]

func _paint_map():
	# ============================================================
	# BASE TERRAIN - Fill with grass (only tile available in atlas)
	# ============================================================
	for y in range(MAP_ROWS):
		for x in range(MAP_COLS):
			$Map.set_cell(Vector2i(x, y), 0, _atlas(AtlasTile.GRASS))

	# ============================================================
	# PATH LAYOUT - Complex path with strategic curves
	# ============================================================
	# Path flow: Left entry (row 1) -> right -> down -> left -> down -> right -> exit
	#
	# Row 0 (y=0):  [ ][ ][ ][ ][ ][ ][ ][ ][ ][ ]
	# Row 1 (y=1):  [E][H][H][H][H][H][H][H][ ][ ]  Entry at (0,1), horizontal to (7,1)
	# Row 2 (y=2):  [ ][ ][ ][ ][ ][ ][ ][H ][ ][ ]  Vertical down at (7,2)
	# Row 3 (y=3):  [ ][ ][H][H][H][H][H][H][ ][ ]  Horizontal left at (7,3) to (2,3)
	# Row 4 (y=4):  [ ][ ][H ][ ][ ][H][H][H][H][H]  Vertical down at (2,4), horizontal right to exit

	# ---- ROW 1: Horizontal road from entry to first turn ----
	# Entry road: use ROAD_H for entry tile
	for x in range(0, 8):
		$Map.set_cell(Vector2i(x, 1), 0, _atlas(AtlasTile.ROAD_H))

	# ---- ROW 2: Vertical road down (using H tile) ----
	$Map.set_cell(Vector2i(7, 2), 0, _atlas(AtlasTile.ROAD_H))

	# ---- ROW 3: Horizontal left from (7,3) to (2,3) ----
	for x in range(2, 8):
		$Map.set_cell(Vector2i(x, 3), 0, _atlas(AtlasTile.ROAD_H))

	# ---- ROW 4: Vertical down at (2,4), then horizontal right to exit ----
	$Map.set_cell(Vector2i(2, 4), 0, _atlas(AtlasTile.ROAD_H))
	for x in range(5, 10):
		$Map.set_cell(Vector2i(x, 4), 0, _atlas(AtlasTile.ROAD_H))

	# ============================================================
	# DECORATIVE ELEMENTS - Skip (not in conservative atlas)
	# ============================================================

func _set_dirt_patch(x: int, y: int, w: int, h: int) -> void:
	# Dirt tiles not available in conservative atlas - no-op for now
	pass

func _set_decor(x: int, y: int, tile: AtlasTile) -> void:
	# Decorative tiles not available in conservative atlas - no-op for now
	pass

func _tile_center_x(tx: int) -> float:
	return tx * TILE_SIZE + TILE_SIZE / 2.0

func _tile_center_y(ty: int) -> float:
	return ty * TILE_SIZE + TILE_SIZE / 2.0

func _setup_path():
	var path := Curve2D.new()

	# Path follows the visual road centers exactly:
	# Entry from left -> (0,1) -> horizontal right -> (7,1) turn down
	# -> (7,2) vertical -> (7,3) turn left -> (6,3) to (3,3) horizontal
	# -> (2,3) turn down -> (2,4) vertical -> (5,4) turn right
	# -> (6,4) to (8,4) horizontal -> Exit right

	var y1 := _tile_center_y(1)  # Row 1: y=192
	var y2 := _tile_center_y(2)  # Row 2: y=320
	var y3 := _tile_center_y(3)  # Row 3: y=448
	var y4 := _tile_center_y(4)  # Row 4: y=576

	var x0 := _tile_center_x(0)  # Col 0: x=64
	var x2 := _tile_center_x(2)  # Col 2: x=320
	var x3 := _tile_center_x(3)  # Col 3: x=448
	var x5 := _tile_center_x(5)  # Col 5: x=704
	var x6 := _tile_center_x(6)  # Col 6: x=832
	var x7 := _tile_center_x(7)  # Col 7: x=960
	var x8 := _tile_center_x(8)  # Col 8: x=1088
	var x9 := _tile_center_x(9)  # Col 9: x=1216

	path.add_point(Vector2(-TILE_SIZE, y1))          # Off-screen entry left of (0,1)
	path.add_point(Vector2(x0, y1))                  # Center of (0,1) - entry tile
	path.add_point(Vector2(x6, y1))                  # Center of (6,1) - before first turn
	path.add_point(Vector2(x7, y1))                  # Center of (7,1) - top-right corner
	path.add_point(Vector2(x7, y2))                  # Center of (7,2) - vertical
	path.add_point(Vector2(x7, y3))                  # Center of (7,3) - bottom-right corner
	path.add_point(Vector2(x3, y3))                  # Center of (3,3) - along horizontal
	path.add_point(Vector2(x2, y3))                  # Center of (2,3) - top-left corner
	path.add_point(Vector2(x2, y4))                  # Center of (2,4) - vertical
	path.add_point(Vector2(x5, y4))                  # Center of (5,4) - bottom-left corner
	path.add_point(Vector2(x8, y4))                  # Center of (8,4) - before exit
	path.add_point(Vector2(x9, y4))                  # Center of (9,4) - exit tile
	path.add_point(Vector2(MAP_COLS * TILE_SIZE + TILE_SIZE / 2.0, y4))  # Off-screen exit right

	$EnemyPath.curve = path

	var entry: Marker2D = $Entry
	entry.position = Vector2(-TILE_SIZE / 2.0, y1)
	var exit: Marker2D = $Exit
	exit.position = Vector2(MAP_COLS * TILE_SIZE + TILE_SIZE / 2.0, y4)

func _on_wave_started(current_wave: int) -> void:
	$UI/WaveLabel.text = "WAVE %d" % current_wave

func _on_enemy_rewarded(amount: int) -> void:
	_money += amount
	_update_money_ui()
	_update_range_preview()

func _update_money_ui() -> void:
	$UI/MoneyLabel.text = "MONEY: $%d" % _money

func _update_base_ui() -> void:
	$UI/BaseLabel.text = "BASE: %d HP" % _base_hp

## An enemy reached the exit: damage the base (no reward). Ends the game with a
## loss when the base drops to zero or below.
func _on_enemy_reached_base(damage: int) -> void:
	if _game_ended:
		return
	_base_hp -= damage
	_update_base_ui()
	if _base_hp <= 0:
		_base_hp = 0
		_end_game("GAME OVER")

## Called by the wave spawner when the last wave's enemies are all gone.
func _on_victory() -> void:
	_end_game("YOU WIN")

func _end_game(text: String) -> void:
	if _game_ended:
		return
	_game_ended = true
	$EndScreen/Center/VBox/StatusLabel.text = text
	$EndScreen.visible = true
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	$WaveSpawner.begin_teardown()
	get_tree().reload_current_scene()

## Minimal per-frame work: track the hovered tile for placement feedback.
## The range preview is NOT redrawn every frame — only when the hover tile
## changes (below) or when selection/placement/money changes (event handlers).
func _process(_delta: float) -> void:
	var tile := _mouse_to_tile(get_global_mouse_position())
	if tile != _hover_tile:
		_hover_tile = tile
		queue_redraw()
		_update_range_preview()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos := get_global_mouse_position()
		var tile := _mouse_to_tile(world_pos)
		if _towers.has(tile):
			_select_tower(_towers[tile])
		else:
			if _selected_tower != null:
				_deselect_tower()
			_try_place_tower(world_pos)

## Converts a world position to tilemap coordinates. Returns (-1,-1) off-map.
func _mouse_to_tile(world_pos: Vector2) -> Vector2i:
	var tile := Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE))
	if tile.x < 0 or tile.y < 0 or tile.x >= MAP_COLS or tile.y >= MAP_ROWS:
		return Vector2i(-1, -1)
	return tile

## Can only place on a terrain tile (grass/dirt/sand) that does not already hold a tower.
## Road tiles (atlas rows 2-6) and decorative tiles (row 7+) are not placeable.
func _can_place(tile: Vector2i) -> bool:
	if tile == Vector2i(-1, -1):
		return false
	if _towers.has(tile):
		return false
	var coords: Vector2i = $Map.get_cell_atlas_coords(tile)
	if coords == Vector2i(-1, -1):
		return false
	# Allow placement on terrain tiles (atlas row 0 = grass variants, row 1 = dirt/sand)
	# Block road tiles (rows 2-6) and decorative (row 7+)
	return coords.y <= 1

func _try_place_tower(world_pos: Vector2) -> void:
	var tile := _mouse_to_tile(world_pos)
	if not _can_place(tile):
		return
	var cost := _preview_cost()
	if _money < cost:
		return

	var tower := _preview_scene().instantiate()
	tower.position = _tile_center(tile)
	$Towers.add_child(tower)
	# Connect tower impact signal for visual feedback
	tower.impact.connect(_on_tower_impact)
	_towers[tile] = tower
	_money -= cost
	_update_money_ui()
	queue_redraw()
	_update_range_preview()

func _on_tower_impact(position: Vector2) -> void:
	var effect := IMPACT_EFFECT.instantiate()
	effect.position = position
	add_child(effect)

func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE_SIZE + TILE_SIZE / 2.0, tile.y * TILE_SIZE + TILE_SIZE / 2.0)

## Placement feedback: green = valid + can afford, yellow = valid but too poor,
## red = invalid (road / off-map / occupied). The range circle is drawn by the
## RangePreview node instead.
func _draw() -> void:
	if _hover_tile == Vector2i(-1, -1):
		return

	var placeable := _can_place(_hover_tile)
	var affordable := _money >= _preview_cost()
	var tile_pos := Vector2(_hover_tile.x * TILE_SIZE, _hover_tile.y * TILE_SIZE)
	var color: Color
	if not placeable:
		color = Color(1.0, 0.3, 0.3, 0.45)
	elif not affordable:
		color = Color(1.0, 0.8, 0.2, 0.45)
	else:
		color = Color(0.3, 1.0, 0.3, 0.45)
	draw_rect(Rect2(tile_pos, Vector2(TILE_SIZE, TILE_SIZE)), color, true)

## Selects a placed tower. The preview then shows that tower's real range.
func _select_tower(tower: Node2D) -> void:
	if _selected_tower == tower:
		return
	_deselect_tower()
	_selected_tower = tower
	# Add selection outline
	tower.modulate = Color(0.8, 1.0, 1.0, 1.0)
	_update_range_preview()
	_update_tower_info_panel()

func _deselect_tower() -> void:
	if _selected_tower != null and is_instance_valid(_selected_tower):
		_selected_tower.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_selected_tower = null
	_update_range_preview()
	_update_tower_info_panel()

## Chooses what the RangePreview should draw: the selected tower's range, or the
## placement preview that follows the cursor.
func _update_range_preview() -> void:
	if is_instance_valid(_selected_tower):
		var tower: Node2D = _selected_tower
		$RangePreview.show_range(tower.position, tower.range, Color(0.4, 0.9, 1.0))
		return

	var tile := _hover_tile
	if tile == Vector2i(-1, -1):
		$RangePreview.hide_range()
		return

	var valid := _can_place(tile)
	var affordable := _money >= _preview_cost()
	var color: Color
	if not valid:
		color = Color(1.0, 0.3, 0.3, 0.9)
	elif not affordable:
		color = Color(1.0, 0.8, 0.2, 0.9)
	else:
		color = Color(0.3, 1.0, 0.3, 0.9)
	$RangePreview.show_range(_tile_center(tile), _preview_range(), color)

func _update_tower_info_panel() -> void:
	var panel = $UI/TowerInfoPanel
	if is_instance_valid(_selected_tower):
		var tower: Node2D = _selected_tower
		panel.visible = true
		panel.get_node("VBox/DamageLabel").text = "Damage: %d" % tower.damage
		panel.get_node("VBox/RangeLabel").text = "Range: %d" % tower.range
		panel.get_node("VBox/AttackSpeedLabel").text = "Attack Speed: %.1f" % tower.attack_speed
		panel.get_node("VBox/CostLabel").text = "Cost: $%d" % tower.cost
		panel.get_node("VBox/LevelLabel").text = "Level: %d" % tower.level
		
		var upgrade_btn = panel.get_node("VBox/UpgradeButton")
		var upgrade_cost: int = tower.get_upgrade_cost()
		if upgrade_cost >= 0:
			upgrade_btn.text = "UPGRADE $%d" % upgrade_cost
			upgrade_btn.disabled = (_money < upgrade_cost)
		else:
			upgrade_btn.text = "MAX LEVEL"
			upgrade_btn.disabled = true
	else:
		panel.visible = false

func _on_upgrade_pressed() -> void:
	if not is_instance_valid(_selected_tower):
		return
	var tower: Node2D = _selected_tower
	var cost: int = tower.get_upgrade_cost()
	if cost < 0:
		return
	if _money < cost:
		return
	
	_money -= cost
	_money = max(_money, 0)
	_update_money_ui()
	
	tower.try_upgrade()
	_update_tower_info_panel()
	_update_range_preview()

func _set_tower_type(type_idx: int) -> void:
	_tower_type_to_place = type_idx
	_update_shop_ui()
	_update_range_preview()

func _update_shop_ui() -> void:
	var shop = $UI/TowerShop
	shop.get_node("VBox/BasicButton").disabled = (_tower_type_to_place == 0)
	shop.get_node("VBox/RapidButton").disabled = (_tower_type_to_place == 1)
