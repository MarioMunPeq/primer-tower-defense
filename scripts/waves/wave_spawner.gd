extends Node2D
## Manages waves of enemies. Spawns enemies one by one along EnemyPath,
## waits for the wave to clear, then starts the next wave after a short rest.

signal wave_started(current_wave: int)
signal enemy_rewarded(amount: int)
signal enemy_reached_base(damage: int)
signal game_complete

const BASIC_ENEMY := preload("res://scenes/enemies/basic_enemy.tscn")

## Waves are defined as data so new waves can be added without touching logic.
## Each entry is: { "count": number of enemies, "interval": seconds between spawns }
## The game wins after this finite set of waves is cleared.
const WAVES: Array[Dictionary] = [
	{ "count": 5, "interval": 1.0 },
	{ "count": 8, "interval": 0.8 },
	{ "count": 12, "interval": 0.7 },
	{ "count": 16, "interval": 0.6 },
	{ "count": 20, "interval": 0.5 },
]

## Number of waves (for victory). Should match WAVES.size().
const TOTAL_WAVES := 5
const INTER_WAVE_DELAY := 3.0

## Damage dealt to the base each time an enemy reaches the end.
const BASE_ENEMY_DAMAGE := 10

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
				if _spawned >= _current_wave_count():
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
					_rest_timer = INTER_WAVE_DELAY
					_state = "resting"
		"resting":
			_rest_timer -= delta
			if _rest_timer <= 0.0:
				_start_next_wave()

## Picks a wave config for the current display wave. Loops back to the first
## config after the last defined wave so the game keeps going.
func _wave_config() -> Dictionary:
	return WAVES[(_display_wave - 1) % WAVES.size()]

func _current_wave_count() -> int:
	return int(_wave_config()["count"])

func _current_wave_interval() -> float:
	return float(_wave_config()["interval"])

func _start_next_wave() -> void:
	if _state == "finished":
		return
	_display_wave += 1
	_spawned = 0
	_spawn_timer = 0.0
	_state = "spawning"
	wave_started.emit(_display_wave)

func _spawn_enemy() -> void:
	if _alive >= MAX_LIVE_ENEMIES:
		push_warning("WaveSpawner hit live-enemy ceiling (%d); deferring spawn until enemies clear." % MAX_LIVE_ENEMIES)
		return

	var follow := PathFollow2D.new()
	follow.rotates = false
	follow.loop = false
	_enemy_path.add_child(follow)

	var enemy := BASIC_ENEMY.instantiate()
	follow.add_child(enemy)

	_alive += 1
	enemy.tree_exited.connect(_on_enemy_gone)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_base.connect(_on_enemy_reached_base)

func _on_enemy_gone() -> void:
	if _tearing_down:
		return
	_alive -= 1
	if _alive < 0:
		_alive = 0
		push_warning("WaveSpawner counted a negative live-enemy amount; clamped to 0.")

func _on_enemy_died(reward_amount: int) -> void:
	enemy_rewarded.emit(reward_amount)

func _on_enemy_reached_base() -> void:
	enemy_reached_base.emit(BASE_ENEMY_DAMAGE)
