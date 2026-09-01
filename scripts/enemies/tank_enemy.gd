extends "res://scripts/enemies/enemy_base.gd"
## Tank enemy: ~4x HP of Basic, ~50% speed. Big sprite, red/brown accents and
## 1 flat damage reduction (never below 1 damage).

func _init() -> void:
	speed = 50.0
	health = 16
	reward = 30
	base_damage = 2
	damage_reduction = 1
	hp_bar_width = 64.0
	ring_color = Color(1.0, 0.4, 0.3, 0.3)
	death_start_color = Color(0.85, 0.35, 0.2, 1)
	death_end_color = Color(1.0, 0.55, 0.35, 1)