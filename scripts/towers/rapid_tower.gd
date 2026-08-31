extends "res://scripts/towers/tower_base.gd"
## Rapid Tower: lower damage per hit, much faster attack speed, shorter range.

const RANGE := 150.0
const DAMAGE := 1
const ATTACK_COOLDOWN := 0.33
const COST := 75
const MAX_PROJECTILES_CONST := 12

# Values are set in the scene file (rapid_tower.tscn)
# Range: 150, Damage: 1, Attack Cooldown: 0.33, Cost: 75

## Slightly snappier fire feedback for rapid tower.
func _fire_feedback() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color(1.3, 1.5, 1.3, 1.0), 0.03)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.07)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.03)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.07)