extends Node
## Global audio singleton (autoload "GameAudio"). Survives scene changes so the
## music keeps playing from the main menu into the game and back.
##
## Two responsibilities:
##  - A round-robin pool of reusable AudioStreamPlayers for one-shot SFX, so big
##    waves never create/destroy players per shot.
##  - A single looping background track whose volume is driven by the Options
##    menu (Settings.music_volume).
##
## ---------------------------------------------------------------
## PLACEHOLDER ASSET PATHS
## ---------------------------------------------------------------
## The project has no audio files yet. All paths below are resolved at runtime
## with load() (never preload), so missing files fail soft with a warning instead
## of breaking the build. Drop the CC0 packs into the folders and it just works:
##   - res://assets/audio/sfx/   Kenney "Impact Sounds" + "Interface Sounds"
##   - res://assets/audio/music/ Pixabay Music loop
## Adjust the filenames below to match what you download.

const SFX_DIR := "res://assets/audio/sfx"
const MUSIC_DIR := "res://assets/audio/music"

const HIT_FILE := "impact_hit.wav"
const EXPLOSION_FILE := "impact_heavy.wav"
const BASE_HIT_FILE := "hit_hurt.wav"
const UI_CLICK_FILE := "click_soft.wav"
const UI_ERROR_FILE := "error.wav"
const BUY_FILE := "coin_pickup.wav"
const MUSIC_FILE := "background_loop.ogg"

## Number of reusable SFX players in the pool.
const SFX_POOL_SIZE := 12

var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _music: AudioStreamPlayer = null
var _stream_cache := {}

func _ready() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_pool.append(player)
	_setup_music()
	apply_music_volume()

func _setup_music() -> void:
	var stream := _stream(MUSIC_FILE)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music = AudioStreamPlayer.new()
	_music.stream = stream
	add_child(_music)
	_music.play()

## Resolves a file name to its full path: music lives in MUSIC_DIR, everything
## else in SFX_DIR (keyed off the extension).
func _asset_path(file: String) -> String:
	if file.get_extension() in ["ogg", "mp3"]:
		return MUSIC_DIR.path_join(file)
	return SFX_DIR.path_join(file)

## Lazy loader. Returns null (with a warning) instead of crashing when the
## placeholder assets have not been dropped in yet.
func _stream(file: String) -> AudioStream:
	var path := _asset_path(file)
	if _stream_cache.has(path):
		return _stream_cache[path]
	var s: AudioStream = null
	if FileAccess.file_exists(path):
		s = load(path) as AudioStream
	_stream_cache[path] = s
	if s == null:
		push_warning("GameAudio: '%s' no encontrado en '%s'. Añade el fichero para oír el sonido." % [file, path])
	return s

## Plays a one-shot SFX through the next pool player. Voice-stealing by
## round-robin: on very busy frames an old sound may cut off rather than spawn
## a new player (the point of the pool).
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_pool[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_pool.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

## --- Convenience API used by gameplay code --------------------------------
func impact_sfx() -> void:
	play_sfx(_stream(HIT_FILE), -4.0, randf_range(0.95, 1.05))

func explosion_sfx() -> void:
	play_sfx(_stream(EXPLOSION_FILE), -2.0)

func base_hit_sfx() -> void:
	play_sfx(_stream(BASE_HIT_FILE), 0.0)

func ui_click() -> void:
	play_sfx(_stream(UI_CLICK_FILE), -6.0)

func ui_error() -> void:
	play_sfx(_stream(UI_ERROR_FILE), -1.0)

func buy_sfx() -> void:
	play_sfx(_stream(BUY_FILE), -2.0)

## Re-applies the music volume from Settings. Called when the Options slider
## changes, so the user hears the result immediately.
func apply_music_volume() -> void:
	if _music != null:
		_music.volume_db = linear_to_db(clampf(Settings.music_volume, 0.0, 1.0))