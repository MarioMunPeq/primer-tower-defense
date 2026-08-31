extends Node2D

const TILE_SIZE := 128
const MAP_COLS := 10
const MAP_ROWS := 5

const ATLAS_GRASS := Vector2i(0, 0)
const ATLAS_ROAD := Vector2i(1, 0)

const BASIC_TOWER := preload("res://scenes/towers/basic_tower.tscn")
const BASIC_TOWER_SCRIPT := preload("res://scripts/towers/basic_tower.gd")

const TOWER_COST := 50
const BASE_HP_MAX := 100

var _towers := {}
var _hover_tile := Vector2i(-1, -1)
var _money: int = 100
var _selected_tower: Node2D = null
var _base_hp: int = BASE_HP_MAX
var _game_ended := false

## The placement-preview range comes straight from the tower script's single
## source constant (equivalent to BasicTower.range) — no scene is instantiated
## just to read a number, so this is free to call.
func _preview_range() -> float:
	return BASIC_TOWER_SCRIPT.RANGE

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
	_update_money_ui()
	_update_base_ui()

func _setup_tilemap():
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source := TileSetAtlasSource.new()
	source.texture = preload("res://assets/tilesets/map_atlas.png")
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	source.create_tile(ATLAS_GRASS)
	source.create_tile(ATLAS_ROAD)

	ts.add_source(source, 0)
	$Map.tile_set = ts

func _paint_map():
	# Fill the whole map with grass
	for y in range(MAP_ROWS):
		for x in range(MAP_COLS):
			$Map.set_cell(Vector2i(x, y), 0, ATLAS_GRASS)

	# Serpentine path (grid 10x5):
	# Row 1: entry from left, travel right to col 8
	for x in range(0, 9):
		_paint_road(x, 1)
	# Turn down at col 8
	_paint_road(8, 2)
	# Row 3: travel left from col 8 to col 1
	for x in range(1, 9):
		_paint_road(x, 3)
	# Turn down at col 1
	_paint_road(1, 4)
	# Row 4: travel right toward exit (right edge)
	for x in range(2, 10):
		_paint_road(x, 4)

func _paint_road(x: int, y: int):
	$Map.set_cell(Vector2i(x, y), 0, ATLAS_ROAD)

func _tile_center_x(tx: int) -> float:
	return tx * TILE_SIZE + TILE_SIZE / 2.0

func _setup_path():
	var path := Curve2D.new()

	var row_1_y := _tile_center_x(1)
	var row_3_y := _tile_center_x(3)
	var row_4_y := _tile_center_x(4)

	path.add_point(Vector2(-TILE_SIZE, row_1_y))                 # off-screen entry
	path.add_point(Vector2(_tile_center_x(8), row_1_y))          # right end of row 1
	path.add_point(Vector2(_tile_center_x(8), row_3_y))          # bottom of the first turn
	path.add_point(Vector2(_tile_center_x(1), row_3_y))          # left end of row 3
	path.add_point(Vector2(_tile_center_x(1), row_4_y))          # bottom of second turn
	path.add_point(Vector2(MAP_COLS * TILE_SIZE + TILE_SIZE / 2.0, row_4_y))  # off-screen exit

	$EnemyPath.curve = path

	var entry: Marker2D = $Entry
	entry.position = Vector2(-TILE_SIZE / 2.0, row_1_y)
	var exit: Marker2D = $Exit
	exit.position = Vector2(MAP_COLS * TILE_SIZE + TILE_SIZE / 2.0, row_4_y)

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
				_selected_tower = null
				_update_range_preview()
			_try_place_tower(world_pos)

## Converts a world position to tilemap coordinates. Returns (-1,-1) off-map.
func _mouse_to_tile(world_pos: Vector2) -> Vector2i:
	var tile := Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE))
	if tile.x < 0 or tile.y < 0 or tile.x >= MAP_COLS or tile.y >= MAP_ROWS:
		return Vector2i(-1, -1)
	return tile

## Can only place on a grass tile that does not already hold a tower.
func _can_place(tile: Vector2i) -> bool:
	if tile == Vector2i(-1, -1):
		return false
	if _towers.has(tile):
		return false
	return $Map.get_cell_atlas_coords(tile) == ATLAS_GRASS

func _try_place_tower(world_pos: Vector2) -> void:
	var tile := _mouse_to_tile(world_pos)
	if not _can_place(tile):
		return
	if _money < TOWER_COST:
		return

	var tower := BASIC_TOWER.instantiate()
	tower.position = _tile_center(tile)
	$Towers.add_child(tower)
	_towers[tile] = tower
	_money -= TOWER_COST
	_update_money_ui()
	queue_redraw()
	_update_range_preview()

func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE_SIZE + TILE_SIZE / 2.0, tile.y * TILE_SIZE + TILE_SIZE / 2.0)

## Placement feedback: green = valid + can afford, yellow = valid but too poor,
## red = invalid (road / off-map / occupied). The range circle is drawn by the
## RangePreview node instead.
func _draw() -> void:
	if _hover_tile == Vector2i(-1, -1):
		return

	var placeable := _can_place(_hover_tile)
	var affordable := _money >= TOWER_COST
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
	_selected_tower = tower
	_update_range_preview()

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
	var affordable := _money >= TOWER_COST
	var color: Color
	if not valid:
		color = Color(1.0, 0.3, 0.3, 0.9)
	elif not affordable:
		color = Color(1.0, 0.8, 0.2, 0.9)
	else:
		color = Color(0.3, 1.0, 0.3, 0.9)
	$RangePreview.show_range(_tile_center(tile), _preview_range(), color)
