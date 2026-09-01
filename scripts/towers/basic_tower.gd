extends "res://scripts/towers/tower_base.gd"
## Basic Tower: balanced damage and range.

const RANGE := 260.0
const DAMAGE := 1
const ATTACK_COOLDOWN := 0.8
const COST := 50
const MAX_PROJECTILES_CONST := 8

# Stats per level: {damage, range, attack_cooldown}
# BasicTower Level 1: Damage 1, Range 260, Attack cooldown 1.25, Cost 50
# Level 2: Damage 2, Range 285, Attack cooldown 1.10
# Level 3: Damage 3, Range 310, Attack cooldown 0.95

func _init() -> void:
	STATS_PER_LEVEL = [
		{"damage": 1, "range": 260.0, "attack_cooldown": 1.25},   # Level 1
		{"damage": 2, "range": 285.0, "attack_cooldown": 1.10},   # Level 2
		{"damage": 3, "range": 310.0, "attack_cooldown": 0.95}    # Level 3
	]
	UPGRADE_COSTS = [75, 125]  # 1->2: $75, 2->3: $125
	max_level = 3
	cost = COST
	MAX_PROJECTILES = MAX_PROJECTILES_CONST