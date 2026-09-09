extends Node

const SETTINGS_PATH := "user://settings.cfg"

const DEFAULT_FULLSCREEN := false
const DEFAULT_QUALITY := 0
const DEFAULT_DEFAULT_SPEED := 1
const DEFAULT_SELL_CONFIRM := true

var fullscreen: bool = DEFAULT_FULLSCREEN
var quality: int = DEFAULT_QUALITY
var default_speed: int = DEFAULT_DEFAULT_SPEED
var sell_confirm: bool = DEFAULT_SELL_CONFIRM

func _ready() -> void:
	load_settings()
	apply_display_settings()

func _quality_factor() -> float:
	return 1.0 if quality == 0 else 0.75

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	if cfg.has_section_key("display", "fullscreen"):
		fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	if cfg.has_section_key("display", "quality"):
		quality = int(cfg.get_value("display", "quality", quality))
	if cfg.has_section_key("gameplay", "default_speed"):
		default_speed = int(cfg.get_value("gameplay", "default_speed", default_speed))
	if cfg.has_section_key("gameplay", "sell_confirm"):
		sell_confirm = bool(cfg.get_value("gameplay", "sell_confirm", sell_confirm))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "quality", quality)
	cfg.set_value("gameplay", "default_speed", default_speed)
	cfg.set_value("gameplay", "sell_confirm", sell_confirm)
	cfg.save(SETTINGS_PATH)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("FS.syncfs(false, function(err){});")

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	if not OS.has_feature("web"):
		_apply_fullscreen()
	save_settings()

func set_quality(value: int) -> void:
	quality = value
	get_tree().root.content_scale_factor = _quality_factor()
	save_settings()

func set_default_speed(value: int) -> void:
	default_speed = value
	save_settings()

func set_sell_confirm(value: bool) -> void:
	sell_confirm = value
	save_settings()

func apply_display_settings() -> void:
	get_tree().root.content_scale_factor = _quality_factor()
	if not OS.has_feature("web"):
		_apply_fullscreen()

func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)