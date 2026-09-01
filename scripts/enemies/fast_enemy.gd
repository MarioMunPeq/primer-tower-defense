extends "res://scripts/enemies/enemy_base.gd"
## Fast enemy: ~40% less HP than Basic, ~80% faster. Smaller, sleeker sprite
## with cool cyan accents.

func _init() -> void:
	speed = 180.0
	health = 2
	reward = 15
	base_damage = 1
	hp_bar_width = 34.0
	ring_color = Color(0.35, 0.85, 1, 0.25)
	death_start_color = Color(0.3, 0.8, 1, 1)
	death_end_color = Color(0.9, 1, 1, 1)