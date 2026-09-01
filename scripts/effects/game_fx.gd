extends Node
## Global access point for one-shot world effects. main.gd boots an Fx layer and
## a damage-number pool once, then registers them here so every enemy can trigger
## feedback without its own per-scene plumbing (no per-enemy nodes at rest).

const DEATH_EFFECT := preload("res://scenes/effects/death_effect.tscn")

static var fx_layer: Node2D = null
static var damage_pool: Node2D = null

## Called once by main at startup with the world effect containers.
static func register(fx: Node2D, pool: Node2D) -> void:
	fx_layer = fx
	damage_pool = pool

## Spawns a one-shot death burst at a world position using the enemy's palette.
static func death_effect(world_pos: Vector2, colors: Array) -> void:
	if fx_layer == null or not is_instance_valid(fx_layer):
		return
	var effect: GPUParticles2D = DEATH_EFFECT.instantiate()
	effect.global_position = world_pos
	fx_layer.add_child(effect)
	if colors.size() >= 2 and effect.has_method("setup"):
		effect.setup(colors[0], colors[1])

## Shows a small floating amount above the enemy (pooled labels).
static func damage_number(amount: int, world_pos: Vector2) -> void:
	if damage_pool == null or not is_instance_valid(damage_pool):
		return
	if damage_pool.has_method("spawn"):
		damage_pool.spawn(amount, world_pos)