extends "res://scripts/towers/tower_base.gd"
## Rapid Tower: low damage per hit, very fast attack speed, shorter range.
## Special: every hit slows the target (never stacks).

const RANGE := 150.0
const DAMAGE := 1
const ATTACK_COOLDOWN := 0.33
const COST := 75
const MAX_PROJECTILES_CONST := 12

const SPECIAL_ID := "slow"
const SPECIAL_NAME := "Slow"
## Level-1 overview line used by the shop description/tooltip.
const SPECIAL_SUMMARY := "16% · 1s"

# Level 1: Damage 1, Range 150, cooldown 0.33, slow 16% for 1s, cost $75 (also
# slows only the direct target).
# Branch A (damage): each level raises damage per bullet.
# Branch B (speed): fires faster and upgrades the slow to 22%.

func _init() -> void:
	STATS_PER_LEVEL = [
		{"damage": 1, "range": 150.0, "attack_cooldown": 0.33, "special": 0.16},
	]
	BRANCH_A_STATS = [
		{"damage": 2, "range": 165.0, "attack_cooldown": 0.30, "special": 0.16},
		{"damage": 3, "range": 180.0, "attack_cooldown": 0.28, "special": 0.16},
	]
	BRANCH_B_STATS = [
		{"damage": 1, "range": 170.0, "attack_cooldown": 0.22, "special": 0.16},
		{"damage": 1, "range": 185.0, "attack_cooldown": 0.16, "special": 0.22},
	]
	BRANCH_A_COSTS = [100, 130]  # DMG branch: 1->2 $100, 2->3 $130
	BRANCH_B_COSTS = [100, 130]  # SPD branch: 1->2 $100, 2->3 $130
	branch_name_a = "DAMAGE"
	branch_name_b = "SPEED"
	max_level = 3
	cost = COST
	MAX_PROJECTILES = MAX_PROJECTILES_CONST
	special_id = SPECIAL_ID
	special_name = SPECIAL_NAME
	special_value = 0.16
	special_duration = 1.0