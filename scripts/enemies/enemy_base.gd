extends Node2D
## Base enemy class: shared logic + professional presentation for every type.
## Subclasses set the numerical stats; the per-type look (sprite scale, ring
## colour, death palette, HP bar size) lives in the exported properties and is
## tuned per scene.

signal died(reward_amount: int)
signal reached_base(damage: int)

const GameFx := preload("res://scripts/effects/game_fx.gd")

@export var speed: float = 100.0
@export var health: int = 4
@export var reward: int = 10
@export var base_damage: int = 1

## Flat damage reduction applied to every incoming hit (damage never goes below 1).
@export var damage_reduction: int = 0

## HP bar width drawn above the sprite (only while missing health).
@export var hp_bar_width: float = 48.0
## Soft ground ring under the sprite: the main at-a-glance per-type colour cue.
@export var ring_color: Color = Color(1.0, 0.65, 0.3, 0.22)
## Death burst palette: fires `death_start_color` shifting to `death_end_color`.
@export var death_start_color: Color = Color(1.0, 0.4, 0.2, 1.0)
@export var death_end_color: Color = Color(1.0, 0.9, 0.4, 1.0)

var max_health: int = 4

## Guarantees the enemy finishes exactly once (dies OR reaches the base), never
## both, so its reward/damage signals are emitted at most one time.
var _resolved := false

## Current progress along the path (0.0 to curve length). Updated each physics frame.
## Read-only; set automatically from the parent PathFollow2D.
@export var path_progress: float = 0.0

var _sprite: Sprite2D = null
var _bar_y := -40.0
var _ring_pos := Vector2(0.0, 20.0)
var _ring_radius := 24.0
var _grow_tween: Tween = null
## Cached movement refs (set in _ready) so per-frame movement avoids node
## lookups and curve re-baking.
var _follow: PathFollow2D = null
var _curve: Curve2D = null
var _baked_length := 0.0

func _ready() -> void:
	max_health = health
	_follow = get_parent() as PathFollow2D
	if _follow != null:
		var path := _follow.get_parent() as Path2D
		if path != null and path.curve != null:
			_curve = path.curve
			_baked_length = path.curve.get_baked_length()
	_sprite = get_node_or_null("Sprite") as Sprite2D
	if _sprite != null and _sprite.texture != null:
		var w := _sprite.texture.get_width() * _sprite.scale.x
		var h := _sprite.texture.get_height() * _sprite.scale.y
		_bar_y = -h * 0.5 - 9.0
		_ring_pos = Vector2(0.0, h * 0.5 - 2.0)
		_ring_radius = maxf(w * 0.5, 16.0)
	# Spawn: fade in + subtle scale-up so enemies never pop in at full force.
	scale = Vector2(0.7, 0.7)
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	_grow_tween = create_tween().set_parallel(true)
	_grow_tween.tween_property(self, "modulate:a", 1.0, 0.25)
	_grow_tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _follow == null:
		return

	_follow.progress += speed * delta
	path_progress = _follow.progress
	_face_movement_direction()

	if _follow.progress_ratio >= 1.0:
		_reach_end()

## Makes the sprite look along the path tangent so it always faces the travel
## direction. The sprite base art points right (angle 0). Only the Sprite2D is
## rotated: the HP bar and ground ring are drawn on this node, so they stay
## horizontal, and the circular hitbox is unaffected.
func _face_movement_direction() -> void:
	if _sprite == null or _curve == null:
		return
	if _baked_length <= 0.0:
		return
	var p0 := _curve.sample_baked(clampf(_follow.progress - 2.0, 0.0, _baked_length))
	var p1 := _curve.sample_baked(clampf(_follow.progress + 2.0, 0.0, _baked_length))
	var dir: Vector2 = p1 - p0
	if dir.length_squared() > 0.00001:
		_sprite.rotation = dir.angle()

## Applies damage to the enemy. The enemy flashes white, shows a floating number,
## keeps its HP bar updated, and dies (with particles + fade-out) at zero health.
func take_damage(amount: int) -> void:
	if _resolved or health <= 0:
		return
	var hit := maxi(1, amount - damage_reduction)
	health -= hit
	queue_redraw()
	_flash()
	GameFx.damage_number(hit, global_position + Vector2(0.0, -6.0))
	if health <= 0:
		_die()

## Brief white flash on the sprite when hit (works off the parent's alpha so it
## never fights the spawn fade-in or the death fade-out).
func _flash() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color(1.8, 1.8, 1.8)
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", Color.WHITE, 0.1)

func _die() -> void:
	if _resolved:
		return
	_resolved = true
	died.emit(reward)
	GameFx.death_effect(global_position, [death_start_color, death_end_color])
	# Stop moving, fade the sprite out, then free its PathFollow2D.
	set_physics_process(false)
	if _grow_tween != null and _grow_tween.is_valid():
		_grow_tween.kill()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(_free_follow)

## Called when the enemy completes the path. Emits `reached_base` carrying this
## enemy's base damage (no reward for a leaked enemy), then frees itself.
func _reach_end() -> void:
	if _resolved:
		return
	_resolved = true
	reached_base.emit(base_damage)
	_free_follow()

func _free_follow() -> void:
	if _follow != null and is_instance_valid(_follow):
		_follow.queue_free()
	elif is_inside_tree():
		queue_free()

func _draw() -> void:
	if _resolved and modulate.a <= 0.01:
		return
	# Ground ring (per-type colour) rendered before the sprite child on top.
	draw_ellipse(_ring_pos, _ring_radius, _ring_radius * 0.4, ring_color)
	# HP bar only shows while the enemy is damaged (keeps the screen uncluttered).
	if health < max_health:
		_draw_hp_bar()

func _draw_hp_bar() -> void:
	var bar_x := -hp_bar_width * 0.5
	var ratio := clampf(health / float(max_health), 0.0, 1.0)
	var bar_h := 5.0
	draw_rect(Rect2(bar_x, _bar_y, hp_bar_width, bar_h), Color(0.05, 0.05, 0.08, 0.75))
	draw_rect(
		Rect2(bar_x + 1.0, _bar_y + 1.0, maxf((hp_bar_width - 2.0) * ratio, 0.0), bar_h - 2.0),
		_hp_color(ratio)
	)
	draw_rect(Rect2(bar_x, _bar_y, hp_bar_width, bar_h), Color(1, 1, 1, 0.6), false, 1.0)

## Green > yellow > red as the enemy loses health.
func _hp_color(ratio: float) -> Color:
	var yellow := Color(0.95, 0.8, 0.2)
	if ratio > 0.5:
		return yellow.lerp(Color(0.35, 0.9, 0.3), (ratio - 0.5) * 2.0)
	return yellow.lerp(Color(1.0, 0.25, 0.2), (0.5 - ratio) * 2.0)