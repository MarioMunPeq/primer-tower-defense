extends Node2D
## Manages waves of enemies. Spawns enemies one by one along EnemyPath,
## waits for the wave to clear, then starts the next wave after a short rest.

signal wave_started(current_wave: int)
signal enemy_rewarded(amount: int)
signal enemy_reached_base(damage: int)
signal game_complete

const BASIC_ENEMY := preload("res://scenes/enemies/basic_enemy.tscn")
const FAST_ENEMY := preload("res://scenes/enemies/fast_enemy.tscn")
const TANK_ENEMY := preload("res://scenes/enemies/tank_enemy.tscn")

## Waves are defined as data so new waves can be added without touching logic.
## Each entry is a Dictionary with:
##   "enemies": Array of enemy configurations to spawn in sequence
##   "interval": seconds between spawns
##   "inter_wave_delay": delay after wave clears before next (optional, defaults to INTER_WAVE_DELAY)
## Each enemy config: { "type": "basic"/"fast"/"tank", "count": N }
## The game wins after this finite set of waves is cleared.
const WAVES: Array[Dictionary] = [
	# Wave 1: Only basic enemies
	{
		"enemies": [{"type": "basic", "count": 5}],
		"interval": 1.0,
		"inter_wave_delay": 3.0
	},
	# Wave 2: Basic + some fast
	{
		"enemies": [
			{"type": "basic", "count": 4},
			{"type": "fast", "count": 4}
		],
		"interval": 0.8,
		"inter_wave_delay": 3.0
	},
	# Wave 3: Basic + fast + some tank
	{
		"enemies": [
			{"type": "basic", "count": 5},
			{"type": "fast", "count": 4},
			{"type": "tank", "count": 3}
		],
		"interval": 0.7,
		"inter_wave_delay": 3.0
	},
	# Wave 4: More variety
	{
		"enemies": [
			{"type": "basic", "count": 6},
			{"type": "fast", "count": 5},
			{"type": "tank", "count": 5}
		],
		"interval": 0.6,
		"inter_wave_delay": 3.0
	},
	# Wave 5: Mix of all three
	{
		"enemies": [
			{"type": "basic", "count": 7},
			{"type": "fast", "count": 6},
			{"type": "tank", "count": 7}
		],
		"interval": 0.5,
		"inter_wave_delay": 3.0
	}
]

## Number of waves (for victory). Should match WAVES.size().
const TOTAL_WAVES := 5
const INTER_WAVE_DELAY := 3.0

## Safety ceiling on simultaneously-live enemies. Far above normal gameplay
## (50 simultaneous is the design target); prevents a runaway-spawn bug from
## creating unbounded nodes. Reaching it logs a clear warning instead of
## silently growing forever.
const MAX_LIVE_ENEMIES := 250

var _enemy_path: Path2D = null
var _display_wave := 0     # 1-based wave number, keeps increasing
var _spawned := 0          # how many enemies this wave has released
var _alive := 0            # enemies still on the map (not yet freed)
var _spawn_timer := 0.0
var _rest_timer := 0.0
var _state := "idle"       # idle | spawning | clearing | resting | finished
var _started := false
var _victory_sent := false
var _tearing_down := false

## Current wave enemy queue (flattened list of enemy types to spawn).
var _wave_queue: Array = []

## Called by main just before a scene restart. While the old scene tears down its
## children's tree_exited signals still fire; the wave counter no longer matters
## then, so we stop counting to avoid a spurious "negative live enemy" warning.
func begin_teardown() -> void:
	_tearing_down = true

## Called by main to give this spawner the path and start Wave 1.
## Guards against being called more than once (which would double waves/timers).
func setup(enemy_path: Path2D) -> void:
	if _started:
		push_warning("WaveSpawner.setup called more than once; ignoring.")
		return
	_started = true
	_enemy_path = enemy_path
	_start_next_wave()

func _process(delta: float) -> void:
	match _state:
		"spawning":
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				_spawn_enemy()
				_spawned += 1
				if _spawned >= _wave_queue.size():
					_state = "clearing"
				else:
					_spawn_timer = _current_wave_interval()
		"clearing":
			if _alive <= 0:
				if _display_wave >= TOTAL_WAVES:
					if not _victory_sent:
						_victory_sent = true
						game_complete.emit()
					_state = "finished"
				else:
					_rest_timer = _current_inter_wave_delay()
					_state = "resting"
		"resting":
			_rest_timer -= delta
			if _rest_timer <= 0.0:
				_start_next_wave()

## Returns the current wave's configuration.
func _wave_config() -> Dictionary:
	return WAVES[(_display_wave - 1) % WAVES.size()]

## Returns the total number of enemies to spawn this wave.
func _current_wave_count() -> int:
	return _wave_queue.size()

## Returns the spawn interval for the current wave.
func _current_wave_interval() -> float:
	return float(_wave_config()["interval"])

## Returns the inter-wave delay for the current wave.
func _current_inter_wave_delay() -> float:
	var config := _wave_config()
	if config.has("inter_wave_delay"):
		return float(config["inter_wave_delay"])
	return INTER_WAVE_DELAY

## Prepares the next wave: builds the spawn queue from the wave config.
func _start_next_wave() -> void:
	if _state == "finished":
		return
	_display_wave += 1
	_spawned = 0
	_spawn_timer = 0.0
	_wave_queue = _build_wave_queue()
	_state = "spawning"
	wave_started.emit(_display_wave)

## Builds a flat queue of enemy types from the wave configuration.
## e.g., [{"type": "basic", "count": 2}, {"type": "fast", "count": 1}] -> ["basic", "basic", "fast"]
func _build_wave_queue() -> Array:
	var config := _wave_config()
	var queue: Array = []
	for entry in config["enemies"]:
		var enemy_type: String = entry["type"]
		var count: int = int(entry["count"])
		for i in range(count):
			queue.append(enemy_type)
	return queue

func _spawn_enemy() -> void:
	if _alive >= MAX_LIVE_ENEMIES:
		push_warning("WaveSpawner hit live-enemy ceiling (%d); deferring spawn until enemies clear." % MAX_LIVE_ENEMIES)
		return

	var follow := PathFollow2D.new()
	follow.rotates = false
	follow.loop = false
	_enemy_path.add_child(follow)

	var enemy_type: String = _wave_queue[_spawned]
	var enemy_scene := _get_enemy_scene(enemy_type)
	var enemy := enemy_scene.instantiate()
	follow.add_child(enemy)

	_alive += 1
	enemy.tree_exited.connect(_on_enemy_gone)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_base.connect(_on_enemy_reached_base)

func _get_enemy_scene(type: String) -> PackedScene:
	match type:
		"basic": return BASIC_ENEMY
		"fast": return FAST_ENEMY
		"tank": return TANK_ENEMY
		_:
			push_warning("Unknown enemy type '%s', falling back to basic." % type)
			return BASIC_ENEMY

func _on_enemy_gone() -> void:
	if _tearing_down:
		return
	_alive -= 1
	if _alive < 0:
		_alive = 0
		push_warning("WaveSpawner counted a negative live-enemy amount; clamped to 0.")

func _on_enemy_died(reward_amount: int) -> void:
	enemy_rewarded.emit(reward_amount)

func _on_enemy_reached_base(damage: int) -> void:
	# Damage was already read from the enemy's own base_damage before it freed.
	enemy_reached_base.emit(damage)