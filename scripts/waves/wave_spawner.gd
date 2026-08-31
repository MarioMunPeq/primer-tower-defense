extends Node2D
## Manages waves of enemies. Spawns enemies one by one along EnemyPath,
## waits for the wave to clear, then starts the next wave after a short rest.

signal wave_started(current_wave: int)
signal enemy_rewarded(amount: int)

const BASIC_ENEMY := preload("res://scenes/enemies/basic_enemy.tscn")

## Waves are defined as data so new waves can be added without touching logic.
## Each entry is: { "count": number of enemies, "interval": seconds between spawns }
const WAVES: Array[Dictionary] = [
	{ "count": 5, "interval": 1.0 },
	{ "count": 8, "interval": 0.8 },
	{ "count": 12, "interval": 0.7 },
]

const INTER_WAVE_DELAY := 3.0

var _enemy_path: Path2D = null
var _display_wave := 0     # 1-based wave number, keeps increasing
var _spawned := 0          # how many enemies this wave has released
var _alive := 0            # enemies still on the map (not yet freed)
var _spawn_timer := 0.0
var _rest_timer := 0.0
var _state := "idle"       # idle | spawning | clearing | resting

## Called by main to give this spawner the path and start Wave 1.
func setup(enemy_path: Path2D) -> void:
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
	_display_wave += 1
	_spawned = 0
	_spawn_timer = 0.0
	_state = "spawning"
	wave_started.emit(_display_wave)

func _spawn_enemy() -> void:
	var follow := PathFollow2D.new()
	follow.rotates = false
	follow.loop = false
	_enemy_path.add_child(follow)

	var enemy := BASIC_ENEMY.instantiate()
	follow.add_child(enemy)

	_alive += 1
	enemy.tree_exited.connect(_on_enemy_gone)
	enemy.died.connect(_on_enemy_died)

func _on_enemy_gone() -> void:
	_alive -= 1

func _on_enemy_died(reward_amount: int) -> void:
	enemy_rewarded.emit(reward_amount)

## NOTE (future milestone): enemies that reach the end currently just free
## themselves in basic_enemy.gd (_reach_end). When base lives are added, hook
## detection there instead of relying solely on tree_exited.