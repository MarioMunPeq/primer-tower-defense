extends Node2D
## M12: Test de estrés. Construye un pasillo en zigzag con 30 torres básicas
## disparando, y spawnea enemigos básicos a petición. Mide FPS, tiempo de
## frame, contadores de nodos y memoria vía Performance. Incluye un modo
## automático que spawnea enemigos hasta que el FPS baja de 30 (bottleneck).

const BASIC_TOWER := preload("res://scenes/towers/basic_tower.tscn")
const BASIC_ENEMY := preload("res://scenes/enemies/basic_enemy.tscn")

const CORRIDOR_Y := [128.0, 288.0, 448.0, 608.0]   # 4 filas del zigzag
const CORRIDOR_X_MIN := 60.0
const CORRIDOR_X_MAX := 1220.0
const TOWER_OFFSET_Y := 150.0                      # distancia perpendicular torre->pasillo
const TOWER_SPACING := 140.0
const SPAWN_INTERVAL := 0.05                       # 20 enemigos/segundo
const MAX_ALIVE := 500                             # techo de seguridad
const FPS_BOTTLENECK := 30.0

var _path: Path2D = null
var _towers_node: Node2D = null
var _cone_queue: Array = []
var _alive := 0
var _killed := 0
var _leaked := 0
var _spawn_timer := 0.0
var _auto := false
var _auto_since := 0.0
var _fps_low_since := 0.0
var _elapsed := 0.0
var _key_cooldown := 0.0

var _stats_label: Label = null
var _hint_label: Label = null
var _auto_btn: Button = null

func _ready() -> void:
	_build_path()
	_build_towers()
	_build_hud()
	_auto_btn.pressed.connect(_toggle_auto)
	_spawn_burst(100)

func _build_path() -> void:
	_path = Path2D.new()
	_path.name = "EnemyPath"
	add_child(_path)

	var curve := Curve2D.new()
	for i in CORRIDOR_Y.size():
		var y: float = CORRIDOR_Y[i]
		if i % 2 == 0:
			curve.add_point(Vector2(CORRIDOR_X_MIN - 160.0, y))
			curve.add_point(Vector2(CORRIDOR_X_MAX + 160.0, y))
		else:
			curve.add_point(Vector2(CORRIDOR_X_MAX + 160.0, y))
			curve.add_point(Vector2(CORRIDOR_X_MIN - 160.0, y))
	_path.curve = curve

## Coloca 32 torres (8 por fila alternando lados) de modo que cubran el pasillo.
func _build_towers() -> void:
	_towers_node = Node2D.new()
	_towers_node.name = "Towers"
	add_child(_towers_node)

	for row in range(CORRIDOR_Y.size()):
		var y: float = CORRIDOR_Y[row]
		var side := 1.0 if (row % 2) == 0 else -1.0
		var x: float = CORRIDOR_X_MIN + TOWER_SPACING
		while x <= CORRIDOR_X_MAX:
			var tower := BASIC_TOWER.instantiate()
			_towers_node.add_child(tower)
			tower.global_position = Vector2(x, y + TOWER_OFFSET_Y * side)
			x += TOWER_SPACING

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	_stats_label = Label.new()
	_stats_label.position = Vector2(12, 8)
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	layer.add_child(_stats_label)

	_hint_label = Label.new()
	_hint_label.position = Vector2(12, 140)
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35, 1.0))
	layer.add_child(_hint_label)

	var panel := PanelContainer.new()
	panel.position = Vector2(760, 8)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	layer.add_child(panel)

	var spawn100 := Button.new()
	spawn100.text = "Spawn +100 [Espacio]"
	spawn100.pressed.connect(func(): _spawn_burst(100))
	vbox.add_child(spawn100)

	var spawn500 := Button.new()
	spawn500.text = "Spawn +500 [B]"
	spawn500.pressed.connect(func(): _spawn_burst(500))
	vbox.add_child(spawn500)

	_auto_btn = Button.new()
	_auto_btn.text = "Auto: spawnea hasta FPS<30 [A]"
	_auto_btn.toggle_mode = true
	vbox.add_child(_auto_btn)

	var reset := Button.new()
	reset.text = "Reset [R]"
	reset.pressed.connect(_reset_stress)
	vbox.add_child(reset)

	var quit := Button.new()
	quit.text = "Salir [ESC]"
	quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit)

func _toggle_auto() -> void:
	_auto = _auto_btn.button_pressed
	_auto_since = 0.0
	_fps_low_since = 0.0

func _process(delta: float) -> void:
	_elapsed += delta
	_key_cooldown = maxf(_key_cooldown - delta, 0.0)
	_process_input()
	_process_spawner(delta)

	if _auto:
		_auto_since += delta
		if _auto_since >= 1.0:
			_auto_since = 0.0
			_spawn_burst(200)

	var fps := Performance.get_monitor(Performance.TIME_FPS)
	if fps < FPS_BOTTLENECK:
		_fps_low_since += delta
	else:
		_fps_low_since = 0.0

	# El modo auto se apaga solo al detectar un bottleneck sostenido.
	if _auto and _fps_low_since >= 1.0:
		_auto = false
		_auto_btn.button_pressed = false

	_update_stats(fps)

func _process_input() -> void:
	if _key_cooldown > 0.0:
		return
	if Input.is_key_pressed(KEY_SPACE):
		_spawn_burst(100)
		_key_cooldown = 0.25
	elif Input.is_key_pressed(KEY_B):
		_spawn_burst(500)
		_key_cooldown = 0.25
	elif Input.is_key_pressed(KEY_A):
		_auto_btn.button_pressed = not _auto_btn.button_pressed
		_toggle_auto()
		_key_cooldown = 0.25
	elif Input.is_key_pressed(KEY_R):
		_reset_stress()
		_key_cooldown = 0.25

func _process_spawner(delta: float) -> void:
	_spawn_timer -= delta
	while _spawn_timer <= 0.0 and not _cone_queue.is_empty():
		_spawn_timer += SPAWN_INTERVAL
		if _alive >= MAX_ALIVE:
			break
		_spawn_enemy()

func _spawn_burst(count: int) -> void:
	for i in count:
		_cone_queue.append(true)

func _spawn_enemy() -> void:
	_cone_queue.pop_front()
	var follow := PathFollow2D.new()
	follow.rotates = false
	follow.loop = false
	_path.add_child(follow)

	var enemy := BASIC_ENEMY.instantiate()
	follow.add_child(enemy)

	_alive += 1
	enemy.tree_exited.connect(_on_enemy_gone)
	enemy.died.connect(func(_r: int) -> void: _killed += 1)
	enemy.reached_base.connect(func() -> void: _leaked += 1)

func _on_enemy_gone() -> void:
	_alive -= 1
	if _alive < 0:
		_alive = 0

func _update_stats(fps: float) -> void:
	var frame_ms := 0.0
	if fps > 0.0:
		frame_ms = 1000.0 / fps
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var mem_bytes := Performance.get_monitor(Performance.MEMORY_STATIC)
	var mem_mb := mem_bytes / (1024.0 * 1024.0)

	_stats_label.text = "FPS: %d (frame %.1f ms)\nNodos: %d  (huérfanos: %d)\nMemoria: %.1f MB\nCola: %d | Vivos: %d | Muertos: %d | Escapados: %d\nTiempo: %.1f s" % [
		int(fps), frame_ms, int(nodes), int(orphans), mem_mb,
		_cone_queue.size(), _alive, _killed, _leaked, _elapsed]

	if _fps_low_since >= 1.0:
		_hint_label.text = "BOTTLENECK: FPS sustenido < %d (%d nodos).\nReducir Spawn o revisar GPU/CPU." % [int(FPS_BOTTLENECK), int(nodes)]
	elif _family_finished():
		_hint_label.text = "Cola y enemigos agotados: carga estable."
	else:
		_hint_label.text = ""

func _family_finished() -> bool:
	return _cone_queue.is_empty() and _alive == 0

func _reset_stress() -> void:
	_auto_btn.button_pressed = false
	_auto = false
	_cone_queue.clear()
	_alive = 0
	_killed = 0
	_leaked = 0
	_spawn_timer = 0.0
	for child in _path.get_children():
		if child is PathFollow2D:
			child.queue_free()
	for child in _towers_node.get_children():
		child.queue_free()