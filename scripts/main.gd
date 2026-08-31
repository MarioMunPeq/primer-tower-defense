extends Node2D

const TILE_SIZE := 128
const MAP_COLS := 10
const MAP_ROWS := 5

const ATLAS_GRASS := Vector2i(0, 0)
const ATLAS_ROAD := Vector2i(1, 0)

const BASIC_ENEMY := preload("res://scenes/enemies/basic_enemy.tscn")

func _ready():
	_setup_tilemap()
	_paint_map()
	_setup_path()
	_spawn_enemy()

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

func _spawn_enemy():
	# The enemy is placed under a PathFollow2D so it smoothly follows EnemyPath.
	var follow := PathFollow2D.new()
	follow.rotates = false
	follow.loop = false
	$EnemyPath.add_child(follow)

	var enemy := BASIC_ENEMY.instantiate()
	follow.add_child(enemy)
