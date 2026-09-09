extends Node2D

const TILE_SIZE := 128
const MAP_COLS := 14
const MAP_ROWS := 8

# Atlas tile coordinates (atlas_x, atlas_y) in the 1024x256 map_atlas.png grid.
# - GRASS: non-buildable terrain filler (decorative green, tile038)
# - ROAD:  road interior fill (tile050, pure brown - no green seams)
# - SAND:  buildable island (the only place towers can be placed), tile029
# - GRASS_DARK: a slightly darker green for visual variety (decorative), tile045
# The road edge/variants below are the ROAD terrain family: they are needed so
# `set_cells_terrain_connect` can pick the right transition for every cell.
enum AtlasTile {
	GRASS      = 0,   # (0,0)  tile038
	ROAD       = 1,   # (1,0)  tile050 - clean road fill
	SAND       = 2,   # (2,0)  tile029 - buildable island
	GRASS_DARK = 3,   # (3,0)  tile045 - decorative darker green
}

# Atlas coordinate lookup: AtlasTile enum value -> Vector2i(atlas_x, atlas_y)
const ATLAS_COORDS: Dictionary = {
	AtlasTile.GRASS:      Vector2i(0, 0),
	AtlasTile.ROAD:       Vector2i(1, 0),
	AtlasTile.SAND:       Vector2i(2, 0),
	AtlasTile.GRASS_DARK: Vector2i(3, 0),
}

const ATLAS_GRASS := Vector2i(0, 0)          # GRASS
const ATLAS_ROAD := Vector2i(1, 0)           # ROAD fill (pure brown)
const ATLAS_SAND := Vector2i(2, 0)           # SAND
const ATLAS_GRASS_DARK := Vector2i(3, 0)     # GRASS_DARK
const ATLAS_ROAD_H := Vector2i(0, 1)         # ROAD straight horizontal
const ATLAS_ROAD_V := Vector2i(1, 1)         # ROAD straight vertical
const ATLAS_ROAD_CORNER_WS := Vector2i(2, 1) # ROAD corner: from W, exits S
const ATLAS_ROAD_CORNER_NE := Vector2i(3, 1) # ROAD corner: from N, exits E
const ATLAS_ROAD_END_E := Vector2i(4, 1)     # ROAD end: only E neighbour is road
const ATLAS_ROAD_END_W := Vector2i(5, 1)     # ROAD end: only W neighbour is road

const BASIC_TOWER := preload("res://scenes/towers/basic_tower.tscn")
const BASIC_TOWER_SCRIPT := preload("res://scripts/towers/basic_tower.gd")
const RAPID_TOWER := preload("res://scenes/towers/rapid_tower.tscn")
const RAPID_TOWER_SCRIPT := preload("res://scripts/towers/rapid_tower.gd")
const SNIPER_TOWER := preload("res://scenes/towers/sniper_tower.tscn")
const SNIPER_TOWER_SCRIPT := preload("res://scripts/towers/sniper_tower.gd")
const IMPACT_EFFECT := preload("res://scenes/effects/impact_effect.tscn")
const GameFx := preload("res://scripts/effects/game_fx.gd")
const TooltipScene := preload("res://scenes/ui/tooltip.tscn")
const PauseMenuScene := preload("res://scenes/ui/pause_menu.tscn")

const BASE_HP_MAX := 100

## Which tower type is currently selected for placement.
## 0 = Basic Tower, 1 = Rapid Tower, 2 = Sniper Tower
var _tower_type_to_place := 0

var _towers := {}
var _tiles_by_tower := {}
var _hover_tile := Vector2i(-1, -1)
var _money: int = 100
var _selected_tower: Node2D = null
var _base_hp: int = BASE_HP_MAX
var _game_ended := false
var _tooltip: Tooltip = null
var _hovered_tower: Node2D = null
var _hovered_enemy: Node2D = null

## The placement-preview range comes from the currently selected tower type.
func _preview_range() -> float:
	if _tower_type_to_place == 0:
		return BASIC_TOWER_SCRIPT.RANGE
	elif _tower_type_to_place == 1:
		return RAPID_TOWER_SCRIPT.RANGE
	return SNIPER_TOWER_SCRIPT.RANGE

## Cost of the currently selected tower type.
func _preview_cost() -> int:
	if _tower_type_to_place == 0:
		return BASIC_TOWER_SCRIPT.COST
	elif _tower_type_to_place == 1:
		return RAPID_TOWER_SCRIPT.COST
	return SNIPER_TOWER_SCRIPT.COST

## Scene of the currently selected tower type.
func _preview_scene() -> PackedScene:
	if _tower_type_to_place == 0:
		return BASIC_TOWER
	elif _tower_type_to_place == 1:
		return RAPID_TOWER
	return SNIPER_TOWER

func _ready():
	_setup_tilemap()
	_paint_map()
	_setup_path()
	_setup_camera()

	var towers := Node2D.new()
	towers.name = "Towers"
	add_child(towers)

	# World effect layers shared by all enemies: death particles + pooled damage
	# numbers (registered on GameFx so enemies can trigger them without plumbing).
	var fx := Node2D.new()
	fx.name = "Fx"
	add_child(fx)
	var damage_pool := preload("res://scripts/ui/damage_number_pool.gd").new()
	damage_pool.name = "DamageNumbers"
	add_child(damage_pool)
	GameFx.register(fx, damage_pool)

	# Tooltip for UI hover info (tower cards, placed towers, enemies)
	var tooltip := TooltipScene.instantiate()
	tooltip.name = "Tooltip"
	$UI.add_child(tooltip)
	_tooltip = tooltip

	# Connect tower card hover for tooltips
	var grid = $UI/TowerShop/VBox/ShopGrid
	var cards := {
		0: grid.get_node("BasicCard"),
		1: grid.get_node("RapidCard"),
		2: grid.get_node("SniperCard"),
	}
	var scripts := {
		0: BASIC_TOWER_SCRIPT,
		1: RAPID_TOWER_SCRIPT,
		2: SNIPER_TOWER_SCRIPT,
	}
	for idx in [0, 1, 2]:
		var card: Button = cards[idx]
		card.mouse_entered.connect(Callable(self, "_show_tower_card_tooltip").bind(idx))
		card.mouse_exited.connect(_hide_tooltip)

	$WaveSpawner.wave_started.connect(_on_wave_started)
	$WaveSpawner.enemy_rewarded.connect(_on_enemy_rewarded)
	$WaveSpawner.enemy_reached_base.connect(_on_enemy_reached_base)
	$WaveSpawner.game_complete.connect(_on_victory)
	$WaveSpawner.setup($EnemyPath)
	$EndScreen/EndPanel/Center/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	$EndScreen/EndPanel/Center/VBox/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	
	# Connect tower selection buttons
	$UI/TowerShop/VBox/ShopGrid/BasicCard.pressed.connect(Callable(self, "_set_tower_type").bind(0))
	$UI/TowerShop/VBox/ShopGrid/RapidCard.pressed.connect(Callable(self, "_set_tower_type").bind(1))
	$UI/TowerShop/VBox/ShopGrid/SniperCard.pressed.connect(Callable(self, "_set_tower_type").bind(2))
	
	# Connect upgrade + sell buttons
	$UI/TowerInfoPanel/VBox/Actions/UpgradeButton.pressed.connect(_on_upgrade_pressed)
	$UI/TowerInfoPanel/VBox/Actions/SellButton.pressed.connect(_on_sell_pressed)
	
	# Connect speed + pause buttons
	$UI/HUDBar/HUDTop/SpeedPanel/Speed1Button.pressed.connect(Callable(self, "_set_speed").bind(1))
	$UI/HUDBar/HUDTop/SpeedPanel/Speed2Button.pressed.connect(Callable(self, "_set_speed").bind(2))
	$UI/HUDBar/HUDTop/SpeedPanel/Speed3Button.pressed.connect(Callable(self, "_set_speed").bind(3))
	$UI/HUDBar/HUDTop/SpeedPanel/PauseButton.pressed.connect(_on_pause_pressed)
	
	_update_money_ui()
	_update_base_ui()
	_update_tower_info_panel()
	_update_shop_ui()
	_update_wave_state_ui()

func _setup_tilemap():
	# Create the TileSet in code (same as original working approach)
	# The TileSet assigned in the scene is just for the editor; we replace it here.
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source := TileSetAtlasSource.new()
	source.texture = preload("res://assets/tilesets/map_atlas.png")
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Atlas grid (8x2 of 128px): row 0 base tiles, row 1 road terrain family.
	for coord in [
		ATLAS_GRASS, ATLAS_ROAD, ATLAS_SAND, ATLAS_GRASS_DARK,
		ATLAS_ROAD_H, ATLAS_ROAD_V, ATLAS_ROAD_CORNER_WS, ATLAS_ROAD_CORNER_NE,
		ATLAS_ROAD_END_E, ATLAS_ROAD_END_W
	]:
		source.create_tile(coord)

	ts.add_source(source, 0)

	# Terrain set with a single ROAD terrain. Only orthogonal sides matter
	# (MATCH_SIDES): each road cell then picks its transition tile automatically
	# from the road status of its 4 direct neighbours.
	# NOTE: add_terrain_set/add_terrain return void in Godot 4.7, so we read the
	# new indexes back via the counters.
	ts.add_terrain_set()
	var terrain_set: int = ts.get_terrain_sets_count() - 1
	ts.add_terrain(terrain_set)
	var road_terrain: int = ts.get_terrains_count(terrain_set) - 1
	ts.set_terrain_name(terrain_set, road_terrain, "Road")
	ts.set_terrain_set_mode(terrain_set, TileSet.TERRAIN_MODE_MATCH_SIDES)

	# Peering bits per road-family tile. Order of keys is not important.
	var road_peering := {
		ATLAS_ROAD: [
			TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
			TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		],
		ATLAS_ROAD_H: [TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		ATLAS_ROAD_V: [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		ATLAS_ROAD_CORNER_WS: [TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		ATLAS_ROAD_CORNER_NE: [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		ATLAS_ROAD_END_E: [TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
		ATLAS_ROAD_END_W: [TileSet.CELL_NEIGHBOR_LEFT_SIDE],
	}
	for coord in road_peering:
		var data: TileData = source.get_tile_data(coord, 0)
		data.terrain_set = terrain_set
		data.terrain = road_terrain
		for bit in road_peering[coord]:
			data.set_terrain_peering_bit(bit, road_terrain)

	$Map.tile_set = ts

func _atlas(tile: AtlasTile) -> Vector2i:
	return ATLAS_COORDS[tile]

func _paint_map():
	# ============================================================
	# BASE TERRAIN - Fill the whole 14x8 grid with grass
	# ============================================================
	for y in range(MAP_ROWS):
		for x in range(MAP_COLS):
			$Map.set_cell(Vector2i(x, y), 0, _atlas(AtlasTile.GRASS))

	# ============================================================
	# PATH + ISLANDS LAYOUT (14 cols x 8 rows)
	# E = entry road, X = exit road, H = road, T = buildable island
	# Row 0:  all grass
	# Row 1:  E H H (cols 0-2), grass to col 13
	# Row 2:  H at col 2; T islands at cols 4-5 and 8-9, 12-13
	# Row 3:  H cols 2-10 (horizontal road); T at cols 12-13
	# Row 4:  T at cols 1-2; H at col 10; T at cols 12-13
	# Row 5:  T at cols 1-2, 4-5, 8-9, 12-13; H at col 10
	# Row 6:  H at col 10; T at cols 12-13
	# Row 7:  H at cols 10,11,12; X at col 13
	# ============================================================

	# Road cells are collected first and painted with the ROAD terrain at the
	# end so the edge transitions follow the neighbours automatically.
	var road_cells: Array[Vector2i] = []

	# ---- ROW 1: entry + horizontal road (cols 0-2) ----
	for x in range(0, 3):
		road_cells.append(Vector2i(x, 1))

	# ---- ROW 2: vertical road at col 2; islands at 4-5, 8-9, 12-13 ----
	road_cells.append(Vector2i(2, 2))
	for x in [4, 5, 8, 9, 12, 13]:
		$Map.set_cell(Vector2i(x, 2), 0, _atlas(AtlasTile.SAND))

	# ---- ROW 3: horizontal road cols 2-10; island at 12-13 ----
	for x in range(2, 11):
		road_cells.append(Vector2i(x, 3))
	for x in [12, 13]:
		$Map.set_cell(Vector2i(x, 3), 0, _atlas(AtlasTile.SAND))

	# ---- ROW 4: islands at 1-2, 12-13; road at col 10 ----
	for x in [1, 2, 12, 13]:
		$Map.set_cell(Vector2i(x, 4), 0, _atlas(AtlasTile.SAND))
	road_cells.append(Vector2i(10, 4))

	# ---- ROW 5: islands at 1-2, 4-5, 8-9, 12-13; road at col 10 ----
	for x in [1, 2, 4, 5, 8, 9, 12, 13]:
		$Map.set_cell(Vector2i(x, 5), 0, _atlas(AtlasTile.SAND))
	road_cells.append(Vector2i(10, 5))

	# ---- ROW 6: vertical road at col 10; island at 12-13 ----
	road_cells.append(Vector2i(10, 6))
	for x in [12, 13]:
		$Map.set_cell(Vector2i(x, 6), 0, _atlas(AtlasTile.SAND))

	# ---- ROW 7: road cols 10-13 (exit on the right) ----
	for x in range(10, 14):
		road_cells.append(Vector2i(x, 7))

	# ============================================================
	# ROAD - painted via the terrain connect so the road borders blend into
	# the grass automatically (peering bits in the TileSet).
	# ============================================================
	$Map.set_cells_terrain_connect(road_cells, 0, 0, true)

	# ============================================================
	# DECORATIVE VARIETY - a few darker grass patches in empty space
	# ============================================================
	$Map.set_cell(Vector2i(0, 0), 0, _atlas(AtlasTile.GRASS_DARK))
	$Map.set_cell(Vector2i(13, 0), 0, _atlas(AtlasTile.GRASS_DARK))
	$Map.set_cell(Vector2i(0, 3), 0, _atlas(AtlasTile.GRASS_DARK))

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

	# Path follows the visual road centers exactly (14x8 layout):
	# Entry from left -> (0,1) -> (2,1) -> down (2,3) ->
	# right (10,3) -> down (10,7) -> right (13,7) -> Exit right

	var y1 := _tile_center_y(1)   # Row 1: y=192
	var y3 := _tile_center_y(3)   # Row 3: y=448
	var y7 := _tile_center_y(7)   # Row 7: y=960

	var x0 := _tile_center_x(0)   # Col 0: x=64   (entry)
	var x2 := _tile_center_x(2)   # Col 2: x=320
	var x10 := _tile_center_x(10) # Col 10: x=1344
	var x13 := _tile_center_x(13) # Col 13: x=1728 (exit)

	path.add_point(Vector2(-TILE_SIZE, y1))        # Off-screen entry left of (0,1)
	path.add_point(Vector2(x0, y1))                # (0,1) entry
	path.add_point(Vector2(x2, y1))                # (2,1) first turn (down)
	path.add_point(Vector2(x2, y3))                # (2,3) bottom-left turn (right)
	path.add_point(Vector2(x10, y3))               # (10,3) right turn (down)
	path.add_point(Vector2(x10, y7))               # (10,7) bottom right turn (right)
	path.add_point(Vector2(x13, y7))               # (13,7) exit tile
	path.add_point(Vector2(MAP_COLS * TILE_SIZE + TILE_SIZE / 2.0, y7))  # Off-screen exit right

	$EnemyPath.curve = path

	var entry: Marker2D = $Entry
	entry.position = Vector2(-TILE_SIZE / 2.0, y1)
	var exit: Marker2D = $Exit
	exit.position = Vector2(MAP_COLS * TILE_SIZE + TILE_SIZE / 2.0, y7)

## Fits the map into the play area left of the right-side tower panel.
## Map 1792x1024, viewport 1280x720 with a 196px panel on the right and a 64px
## top bar: available play area is ~1068x640, so zoom ≈ 0.6 works.
func _setup_camera():
	var zoom := 0.6
	# Center the map in the play area: x-center at (1280-196)/2, y-center at 392.
	$Camera2D.position = Vector2(
		MAP_COLS * TILE_SIZE * 0.5 - (542.0 - 640.0) / zoom,
		MAP_ROWS * TILE_SIZE * 0.5 - (392.0 - 360.0) / zoom
	)
	$Camera2D.zoom = Vector2(zoom, zoom)

func _on_wave_started(current_wave: int) -> void:
	var total_waves: int = $WaveSpawner.TOTAL_WAVES
	$UI/HUDBar/HUDTop/WavePanel/VBox/WaveRow/WaveLabel.text = "WAVE %d/%d" % [current_wave, total_waves]
	_reset_wave_progress()
	_update_wave_state_ui()

func _reset_wave_progress() -> void:
	var bar: ProgressBar = $UI/HUDBar/HUDTop/WavePanel/VBox/EnemyProgress
	bar.value = 0.0
	bar.max_value = float(max($WaveSpawner._wave_queue.size(), 1))

func _on_enemy_rewarded(amount: int) -> void:
	_money += amount
	_update_money_ui()
	_update_range_preview()
	_update_wave_progress()

func _on_enemy_reached_base(damage: int) -> void:
	if _game_ended:
		return
	_base_hp -= damage
	_update_base_ui()
	_update_wave_progress()
	if _base_hp <= 0:
		_base_hp = 0
		_end_game("GAME OVER")

## Enemies killed or leaked count toward the current wave's progress bar.
func _update_wave_progress() -> void:
	var spawner = $WaveSpawner
	var defeated: int = max(spawner._spawned - spawner._alive, 0)
	var bar: ProgressBar = $UI/HUDBar/HUDTop/WavePanel/VBox/EnemyProgress
	bar.value = float(defeated)
	if spawner._state == "finished":
		bar.value = bar.max_value

func _update_money_ui() -> void:
	$UI/HUDBar/HUDTop/ResourcesPanel/HBox/MoneyLabel.text = "%d" % _money
	_update_shop_ui()

func _update_base_ui() -> void:
	$UI/HUDBar/HUDTop/ResourcesPanel/HBox/BaseLabel.text = "%d" % _base_hp

## Called by the wave spawner when the last wave's enemies are all gone.
func _on_victory() -> void:
	_end_game("YOU WIN")

func _end_game(text: String) -> void:
	if _game_ended:
		return
	_game_ended = true
	var end_panel = $EndScreen/EndPanel/Center/VBox
	var end_title = end_panel.get_node("EndTitle")
	end_title.text = text
	if text == "GAME OVER":
		end_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		end_panel.get_node("EndSubtitle").text = "Your base was destroyed"
	else:
		end_title.add_theme_color_override("font_color", Color(0.3, 1, 0.5, 1))
		end_panel.get_node("EndSubtitle").text = "All waves cleared!"
	
	# Show stats
	var waves_survived: int = $WaveSpawner._display_wave
	if text == "YOU WIN":
		waves_survived = 5
	end_panel.get_node("EndStats").text = "Oleadas: %d\nDinero: $%d\nVida base: %d" % [waves_survived, _money, _base_hp]
	
	$EndScreen.visible = true
	get_tree().paused = true

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

## Minimal per-frame work: track the hovered tile for placement feedback.
## The range preview is NOT redrawn every frame — only when the hover tile
## changes (below) or when selection/placement/money changes (event handlers).
func _process(_delta: float) -> void:
	var tile := _mouse_to_tile(get_global_mouse_position())
	if tile != _hover_tile:
		_hover_tile = tile
		queue_redraw()
		_update_range_preview()
		_update_placement_preview()
	_check_hover_tooltips()

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

## Towers can only be placed on buildable island tiles (SAND, atlas coord (2,0)).
## Grass, road, and decorative tiles are not placeable.
func _can_place(tile: Vector2i) -> bool:
	if tile == Vector2i(-1, -1):
		return false
	if _towers.has(tile):
		return false
	var coords: Vector2i = $Map.get_cell_atlas_coords(tile)
	return coords == ATLAS_SAND

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
	_tiles_by_tower[tower] = tile
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

## Placement feedback: shows ghost tower + range circle while placing.
## Tile rect: red = invalid, yellow = valid but poor, green = valid + affordable.
## Ghost tower: red tint if invalid, yellow if valid but poor, white (alpha 0.6) if ok.
func _draw() -> void:
	if _hover_tile == Vector2i(-1, -1):
		return

	var placeable := _can_place(_hover_tile)
	var affordable := _money >= _preview_cost()
	var tile_pos := Vector2(_hover_tile.x * TILE_SIZE, _hover_tile.y * TILE_SIZE)
	var rect_color: Color
	if not placeable:
		rect_color = Color(1.0, 0.3, 0.3, 0.45)
	elif not affordable:
		rect_color = Color(1.0, 0.8, 0.2, 0.45)
	else:
		rect_color = Color(0.3, 1.0, 0.3, 0.45)
	draw_rect(Rect2(tile_pos, Vector2(TILE_SIZE, TILE_SIZE)), rect_color, true)

	# Draw ghost tower preview (always while placing, tinted by validity)
	var ghost_scene := _preview_scene()
	var ghost := ghost_scene.instantiate()
	ghost.position = _tile_center(_hover_tile)
	if not placeable:
		ghost.modulate = Color(1.0, 0.3, 0.3, 0.6)
	elif not affordable:
		ghost.modulate = Color(1.0, 0.8, 0.2, 0.6)
	else:
		ghost.modulate = Color(1.0, 1.0, 1.0, 0.6)
	if ghost.has_node("Sprite"):
		var sprite: Sprite2D = ghost.get_node("Sprite")
		if sprite.texture:
			draw_texture(sprite.texture, _tile_center(_hover_tile) - sprite.texture.get_size() / 2, ghost.modulate)

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

func _update_placement_preview() -> void:
	# Placement preview is handled in _draw() for ghost tower
	pass

func _update_tower_info_panel() -> void:
	var panel: PanelContainer = $UI/TowerInfoPanel
	if is_instance_valid(_selected_tower):
		var tower: Node2D = _selected_tower
		panel.visible = true
		
		var vbox = panel.get_node("VBox")
		vbox.get_node("TowerTypeLabel").text = tower.name.get_slice("Tower", 0).strip_edges().to_upper() + " TOWER"
		vbox.get_node("LevelLabel").text = "Level: %d" % tower.level
		
		vbox.get_node("StatsGrid/StatDamageValue").text = "%d" % tower.damage
		vbox.get_node("StatsGrid/StatRangeValue").text = "%d" % tower.range
		vbox.get_node("StatsGrid/StatSpeedValue").text = "%.2f/s" % tower.attack_speed
		vbox.get_node("StatsGrid/StatCostValue").text = "$%d" % tower.cost
		
		var upgrade_btn: Button = vbox.get_node("Actions/UpgradeButton")
		var upgrade_cost: int = tower.get_upgrade_cost()
		if upgrade_cost >= 0:
			upgrade_btn.text = "UPGRADE $%d" % upgrade_cost
			upgrade_btn.disabled = (_money < upgrade_cost)
		else:
			upgrade_btn.text = "MAX LEVEL"
			upgrade_btn.disabled = true
		
		var sell_btn: Button = vbox.get_node("Actions/SellButton")
		sell_btn.text = "SELL +$%d" % _sell_value(tower)
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

## Refund for selling a tower: 70% of total invested (base cost + upgrades).
func _sell_value(tower: Node2D) -> int:
	var invested: int = tower.cost
	for i in range(tower.level - 1):
		invested += tower.UPGRADE_COSTS[i]
	return int(round(invested * 0.7))

func _on_sell_pressed() -> void:
	if not is_instance_valid(_selected_tower):
		return
	var tower: Node2D = _selected_tower
	var refund := _sell_value(tower)
	var tile: Vector2i = _tiles_by_tower.get(tower, Vector2i(-1, -1))
	_towers.erase(tile)
	tower.queue_free()
	_money += refund
	_update_money_ui()
	_deselect_tower()
	queue_redraw()

func _set_tower_type(type_idx: int) -> void:
	_tower_type_to_place = type_idx
	_update_shop_ui()
	_update_range_preview()

func _update_shop_ui() -> void:
	var grid = $UI/TowerShop/VBox/ShopGrid
	var cards := {
		0: grid.get_node("BasicCard"),
		1: grid.get_node("RapidCard"),
		2: grid.get_node("SniperCard"),
	}
	var scripts := {
		0: BASIC_TOWER_SCRIPT,
		1: RAPID_TOWER_SCRIPT,
		2: SNIPER_TOWER_SCRIPT,
	}

	# Give each card its lock state and cost label. Then highlight the active one.
	# (Never use `disabled`: it greys the button out, which conflicts with the
	# bright "selected" highlight and stops re-clicking to confirm.)
	for idx in cards:
		var card: Button = cards[idx]
		var cost: int = scripts[idx].COST
		var unlocked: bool = _money >= cost
		card.get_node("CardLock").visible = not unlocked
		if not unlocked:
			card.modulate = Color(0.45, 0.45, 0.5, 1.0)
		else:
			card.modulate = Color(1.0, 1.0, 1.0, 1.0)
		card.get_node("CardCostBg/CardCost").text = "$%d" % cost
		card.disabled = false
		card.theme_type_variation = ""
		card.pivot_offset = card.size / 2.0
		card.scale = Vector2.ONE

	var active: Button = cards[_tower_type_to_place]
	active.theme_type_variation = "TowerCardSelected"
	active.pivot_offset = active.size / 2.0
	active.scale = Vector2(1.05, 1.05)
	_update_shop_desc()

## Small info line below the tower grid describing the selected tower.
func _update_shop_desc() -> void:
	var desc := ""
	if _tower_type_to_place == 0:
		desc = "Basic Tower\nDMG %d • RNG %d\n%.2f/s — $%d" % [
			BASIC_TOWER_SCRIPT.DAMAGE, BASIC_TOWER_SCRIPT.RANGE,
			1.0 / BASIC_TOWER_SCRIPT.ATTACK_COOLDOWN, BASIC_TOWER_SCRIPT.COST]
	elif _tower_type_to_place == 1:
		desc = "Rapid Tower\nDMG %d • RNG %d\n%.2f/s — $%d" % [
			RAPID_TOWER_SCRIPT.DAMAGE, RAPID_TOWER_SCRIPT.RANGE,
			1.0 / RAPID_TOWER_SCRIPT.ATTACK_COOLDOWN, RAPID_TOWER_SCRIPT.COST]
	else:
		desc = "Sniper Tower\nDMG %d • RNG %d\n%.2f/s — $%d" % [
			SNIPER_TOWER_SCRIPT.DAMAGE, SNIPER_TOWER_SCRIPT.RANGE,
			1.0 / SNIPER_TOWER_SCRIPT.ATTACK_COOLDOWN, SNIPER_TOWER_SCRIPT.COST]
	$UI/TowerShop/VBox/ShopDesc.text = desc

func _set_speed(multiplier: int) -> void:
	Engine.time_scale = float(multiplier)
	for i in [1, 2, 3]:
		var btn: Button = $UI/HUDBar/HUDTop/SpeedPanel.get_node("Speed%dButton" % i)
		if i == multiplier:
			btn.theme_type_variation = "speed_active"
		else:
			btn.theme_type_variation = "speed"

func _on_pause_pressed() -> void:
	if _game_ended:
		return
	var menu := PauseMenuScene.instantiate()
	menu.resume_requested.connect(_on_pause_resume)
	menu.restart_requested.connect(_on_pause_restart)
	menu.main_menu_requested.connect(_on_pause_main_menu)
	$UI.add_child(menu)
	get_tree().paused = true
	var btn: Button = $UI/HUDBar/HUDTop/SpeedPanel/PauseButton
	btn.text = "▶"
	btn.theme_type_variation = "speed_active"

func _on_pause_resume() -> void:
	get_tree().paused = false
	var btn: Button = $UI/HUDBar/HUDTop/SpeedPanel/PauseButton
	btn.text = "❚❚"
	btn.theme_type_variation = "speed"

func _on_pause_restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_set_speed(1)
	$WaveSpawner.begin_teardown()
	get_tree().reload_current_scene()

func _on_pause_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_restart_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_set_speed(1)
	$WaveSpawner.begin_teardown()
	get_tree().reload_current_scene()

func _update_wave_state_ui() -> void:
	var wave_label = $UI/HUDBar/HUDTop/WavePanel/VBox/WaveRow/WaveStateLabel
	var spawner = $WaveSpawner
	if spawner._state == "spawning":
		wave_label.text = "SPAWNING"
		wave_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4, 1))
	elif spawner._state == "clearing":
		wave_label.text = "CLEARING"
		wave_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1, 1))
	elif spawner._state == "resting":
		wave_label.text = "PREPARING"
		wave_label.add_theme_color_override("font_color", Color(0.5, 1, 0.6, 1))
	elif spawner._state == "finished":
		wave_label.text = "VICTORY"
		wave_label.add_theme_color_override("font_color", Color(0.3, 1, 0.5, 1))
	else:
		wave_label.text = "IDLE"
		wave_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 1))

## Tooltip for tower cards in the shop
func _show_tower_card_tooltip(idx: int) -> void:
	if _tooltip == null:
		return
	var scripts: Dictionary = {0: BASIC_TOWER_SCRIPT, 1: RAPID_TOWER_SCRIPT, 2: SNIPER_TOWER_SCRIPT}
	var scr := scripts[idx] as GDScript
	var name: String = ["Basic", "Rapid", "Sniper"][idx]
	var descr: String = ["Ideal contra oleadas rápidas y numerosas.",
		"Dispara rápido, alcance corto. Para enemigos débiles y rápidos.",
		"Alto daño, gran alcance, cadencia lenta. Para tanques y jefes."][idx]
	var text: String = "%s Tower\nDMG %d  RNG %d  %.2f/s\n$%d\n%s" % [
		name, scr.DAMAGE, scr.RANGE, 1.0 / scr.ATTACK_COOLDOWN, scr.COST, descr]
	_tooltip.show_for(text)

## Tooltip for a placed tower on the map
func _show_tower_tooltip(tower: Node2D) -> void:
	if _tooltip == null:
		return
	var name := tower.name.get_slice("Tower", 0).strip_edges().to_upper()
	var text := "%s Tower (Lvl %d)\nDMG %d  RNG %d  %.2f/s" % [
		name, tower.level, tower.damage, tower.range, tower.attack_speed]
	_tooltip.show_for(text)

## Tooltip for an enemy on the map
func _show_enemy_tooltip(enemy: Node2D) -> void:
	if _tooltip == null:
		return
	var etype := enemy.name.get_slice("Enemy", 0).strip_edges().to_upper()
	var text := "%s\nHP %d/%d  SPD %.0f" % [etype, enemy.health, enemy.max_health, enemy.speed]
	_tooltip.show_for(text)

func _hide_tooltip() -> void:
	if _tooltip != null:
		_tooltip.hide_tooltip()

## Checks hover over placed towers and enemies each frame for tooltips
func _check_hover_tooltips() -> void:
	if _tooltip == null:
		return
	var mouse_pos := get_global_mouse_position()
	
	# Check placed towers
	var tower := _find_tower_at(mouse_pos)
	if tower != _hovered_tower:
		if _hovered_tower != null:
			_hide_tooltip()
		if tower != null:
			_show_tower_tooltip(tower)
		_hovered_tower = tower
		return
	
	# Check enemies (only if no tower hovered)
	if tower == null:
		var enemy := _find_enemy_at(mouse_pos)
		if enemy != _hovered_enemy:
			if _hovered_enemy != null:
				_hide_tooltip()
			if enemy != null:
				_show_enemy_tooltip(enemy)
			_hovered_enemy = enemy
		return
	
	# No tower or enemy under cursor
	if _hovered_tower != null or _hovered_enemy != null:
		_hide_tooltip()
		_hovered_tower = null
		_hovered_enemy = null

func _find_tower_at(world_pos: Vector2) -> Node2D:
	for tile in _towers:
		var t: Node2D = _towers[tile]
		if is_instance_valid(t):
			var hb := t.get_node_or_null("Hitbox") as Area2D
			if hb != null:
				var shape := hb.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if shape != null and shape.shape is CircleShape2D:
					var circle: CircleShape2D = shape.shape
					var radius := circle.radius * maxf(hb.global_scale.x, hb.global_scale.y)
					if hb.global_position.distance_to(world_pos) <= radius:
						return t
	return null

func _find_enemy_at(world_pos: Vector2) -> Node2D:
	# Enemies are children of PathFollow2D under EnemyPath
	var path := $EnemyPath
	for pf in path.get_children():
		if pf is PathFollow2D:
			for child in pf.get_children():
				if child is Node2D and child.has_method("take_damage"):
					var hb := child.get_node_or_null("Hitbox") as Area2D
					if hb != null:
						var shape := hb.get_node_or_null("CollisionShape2D") as CollisionShape2D
						if shape != null and shape.shape is CircleShape2D:
							var circle: CircleShape2D = shape.shape
							var radius := circle.radius * maxf(hb.global_scale.x, hb.global_scale.y)
							if hb.global_position.distance_to(world_pos) <= radius:
								return child
	return null
