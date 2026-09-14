extends "res://scripts/enemies/enemy_base.gd"
## Swarm enemy: the chaff of the flock. 1 HP, quick, cheap reward. Dies to any
## hit, so AoE towers (splash / frost) mulch through packs of them.
## Small pale sprite, soft lime ring.

func _init() -> void:
	speed = 140.0
	health = 1
	reward = 4
	base_damage = 1
	hp_bar_width = 28.0
	ring_color = Color(0.55, 1.0, 0.45, 0.25)
	death_start_color = Color(0.55, 0.95, 0.45, 1.0)
	death_end_color = Color(1.0, 1.0, 0.85, 1.0)