extends "res://scripts/enemies/enemy_base.gd"
## Splitter enemy: medium HP, medium speed. On death it splits into two small,
## fast melee units that keep advancing from its current position. AoE towers
## (splash / frost) are the efficient counter; single-target towers feed it.

const SPLIT_SCENE := preload("res://scenes/enemies/split_enemy.tscn")

func _init() -> void:
	speed = 90.0
	health = 8
	reward = 14
	base_damage = 1
	hp_bar_width = 44.0
	ring_color = Color(0.8, 0.55, 1.0, 0.28)
	death_start_color = Color(0.8, 0.55, 1.0, 1.0)
	death_end_color = Color(0.95, 0.85, 1.0, 1.0)

## Splits into two mini units right where the splitter died, continuing along
## the same path offset. The wave spawner is notified via `spawned_subunits`
## so the extra enemies are counted as live and cleared properly.
func _on_death() -> void:
	var follow := get_parent() as PathFollow2D
	if follow == null:
		return
	var path := follow.get_parent() as Path2D
	if path == null or path.curve == null:
		return
	var units: Array = []
	for i in 2:
		var sub_follow := PathFollow2D.new()
		sub_follow.rotates = false
		sub_follow.loop = false
		path.add_child(sub_follow)
		sub_follow.progress = follow.progress
		var unit := SPLIT_SCENE.instantiate()
		sub_follow.add_child(unit)
		units.append(unit)
	spawned_subunits.emit(units)