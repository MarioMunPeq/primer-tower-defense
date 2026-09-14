extends "res://scripts/enemies/enemy_base.gd"
## Split unit: the two fast little melee units a Splitter spawns on death.
## Tiny, 1 HP, with a small reward. Does not split further.

func _init() -> void:
	speed = 195.0
	health = 1
	reward = 4
	base_damage = 1
	hp_bar_width = 22.0
	ring_color = Color(0.95, 0.8, 1.0, 0.25)
	death_start_color = Color(0.9, 0.75, 1.0, 1.0)
	death_end_color = Color(1.0, 0.95, 1.0, 1.0)