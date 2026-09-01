extends "res://scripts/towers/tower_base.gd"
## Sniper Tower: very long range, high damage per shot, slow attack speed.

const RANGE := 480.0
const DAMAGE := 4
const ATTACK_COOLDOWN := 2.0
const COST := 120
const MAX_PROJECTILES_CONST := 1

# Stats per level: {damage, range, attack_cooldown}
# Level 1: Damage 4, Range 480, Attack cooldown 2.00, Cost 120
# Level 2: Damage 6, Range 540, Attack cooldown 1.90
# Level 3: Damage 8, Range 600, Attack cooldown 1.80

func _init() -> void:
	STATS_PER_LEVEL = [
		{"damage": 4, "range": 480.0, "attack_cooldown": 2.0},   # Level 1
		{"damage": 6, "range": 540.0, "attack_cooldown": 1.9},   # Level 2
		{"damage": 8, "range": 600.0, "attack_cooldown": 1.8}    # Level 3
	]
	UPGRADE_COSTS = [150, 200]  # 1->2: $150, 2->3: $200
	max_level = 3
	cost = COST
	MAX_PROJECTILES = MAX_PROJECTILES_CONST