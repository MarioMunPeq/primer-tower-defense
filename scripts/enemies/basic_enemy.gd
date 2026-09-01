extends "res://scripts/enemies/enemy_base.gd"
## Basic enemy: the reference type. Medium HP, medium speed, no resistances.
## Medium sprite, warm orange accents.

func _init() -> void:
	speed = 100.0
	health = 4
	reward = 10
	base_damage = 1
	hp_bar_width = 48.0
	ring_color = Color(1.0, 0.65, 0.3, 0.22)
	death_start_color = Color(1.0, 0.4, 0.2, 1.0)
	death_end_color = Color(1.0, 0.9, 0.4, 1.0)