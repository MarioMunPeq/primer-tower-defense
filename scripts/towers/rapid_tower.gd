extends "res://scripts/towers/tower_base.gd"
## Rapid Tower: lower damage per hit, much faster attack speed, shorter range.

const RANGE := 150.0
const DAMAGE := 1
const ATTACK_COOLDOWN := 0.33
const COST := 75
const MAX_PROJECTILES_CONST := 12

# Level 1: Damage 1, Range 150, Attack cooldown 0.33, Cost 75
# Level 2: Damage 2, Range 165, Attack cooldown 0.29
# Level 3: Damage 3, Range 180, Attack cooldown 0.25

func _init() -> void:
	STATS_PER_LEVEL = [
		{"damage": 1, "range": 150.0, "attack_cooldown": 0.33},   # Level 1
		{"damage": 2, "range": 165.0, "attack_cooldown": 0.29},   # Level 2
		{"damage": 3, "range": 180.0, "attack_cooldown": 0.25}    # Level 3
	]
	UPGRADE_COSTS = [100, 150]  # 1->2: $100, 2->3: $150
	max_level = 3
	cost = COST
	MAX_PROJECTILES = MAX_PROJECTILES_CONST