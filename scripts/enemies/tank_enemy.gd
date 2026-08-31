extends "res://scripts/enemies/enemy_base.gd"
## Tank enemy: high HP, low speed, higher base damage.

func _init() -> void:
	speed = 55.0
	health = 8
	reward = 25
	base_damage = 2