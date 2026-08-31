extends "res://scripts/enemies/enemy_base.gd"
## Fast enemy: low HP, high speed.

func _init() -> void:
	speed = 170.0
	health = 2
	reward = 15
	base_damage = 1