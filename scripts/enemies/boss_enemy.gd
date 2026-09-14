extends "res://scripts/enemies/enemy_base.gd"
## Boss enemy: the wave-10 juggernaut. Huge HP and base damage, flat armor.
## Slow but inevitable; armour-piercing shots (Sniper) shine here.
## Big sprite, eager red ring and wide HP bar.

func _init() -> void:
	speed = 35.0
	health = 60
	reward = 500
	base_damage = 3
	damage_reduction = 1
	hp_bar_width = 120.0
	ring_color = Color(1.0, 0.25, 0.2, 0.32)
	death_start_color = Color(1.0, 0.3, 0.2, 1.0)
	death_end_color = Color(1.0, 0.75, 0.4, 1.0)