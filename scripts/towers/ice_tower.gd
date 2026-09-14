extends "res://scripts/towers/tower_base.gd"
## Cryo Tower: area frost. Every projectile slows every enemy near the impact
## point. Deals light direct damage, so it shines as a support tower.

const RANGE := 200.0
const DAMAGE := 1
const ATTACK_COOLDOWN := 1.4
const COST := 100
const MAX_PROJECTILES_CONST := 6

## Base slow factor applied to everything in the frost radius.
const FROST_SLOW := 0.30

const SPECIAL_ID := "frost"
const SPECIAL_NAME := "Freeze"
## Level-1 overview line used by the shop description/tooltip.
const SPECIAL_SUMMARY := "70px · 30%"

# Level 1: Damage 1, Range 200, cooldown 1.4, frost 70px / 30% / 1.2s, cost $100.
# Branch A (damage): raises the direct damage without touching the frost.
# Branch B (speed): fires faster and widens + strengthens the frost at max level.

func _init() -> void:
	STATS_PER_LEVEL = [
		{"damage": 1, "range": 200.0, "attack_cooldown": 1.4, "special": 70.0},
	]
	BRANCH_A_STATS = [
		{"damage": 2, "range": 215.0, "attack_cooldown": 1.30, "special": 70.0},
		{"damage": 3, "range": 230.0, "attack_cooldown": 1.20, "special": 70.0},
	]
	BRANCH_B_STATS = [
		{"damage": 1, "range": 225.0, "attack_cooldown": 1.05, "special": 70.0},
		{"damage": 1, "range": 240.0, "attack_cooldown": 0.85, "special": 95.0, "special_extra": 0.38},
	]
	BRANCH_A_COSTS = [75, 100]  # DMG branch: 1->2 $75, 2->3 $100
	BRANCH_B_COSTS = [75, 100]  # SPD branch: 1->2 $75, 2->3 $100
	branch_name_a = "DAMAGE"
	branch_name_b = "SPEED"
	max_level = 3
	cost = COST
	MAX_PROJECTILES = MAX_PROJECTILES_CONST
	special_id = SPECIAL_ID
	special_name = SPECIAL_NAME
	special_value = 70.0
	special_extra = FROST_SLOW
	special_duration = 1.2