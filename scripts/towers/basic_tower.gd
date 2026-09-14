extends "res://scripts/towers/tower_base.gd"
## Basic Tower: balanced damage and an area splash on every hit.

const RANGE := 260.0
const DAMAGE := 1
const ATTACK_COOLDOWN := 0.8
const COST := 50
const MAX_PROJECTILES_CONST := 8

const SPECIAL_ID := "splash"
const SPECIAL_NAME := "Splash"
## Level-1 overview line used by the shop description/tooltip.
const SPECIAL_SUMMARY := "46px"

# Level 1: Damage 1, Range 260, cooldown 1.25, splash 46px, cost $50.
# Branch A (damage): each level raises damage and widens the splash.
# Branch B (speed): close-range rapid fire with a bigger splash at max level.

func _init() -> void:
	STATS_PER_LEVEL = [
		{"damage": 1, "range": 260.0, "attack_cooldown": 1.25, "special": 46.0},
	]
	BRANCH_A_STATS = [
		{"damage": 2, "range": 275.0, "attack_cooldown": 1.15, "special": 58.0},
		{"damage": 3, "range": 290.0, "attack_cooldown": 1.05, "special": 72.0},
	]
	BRANCH_B_STATS = [
		{"damage": 1, "range": 285.0, "attack_cooldown": 0.85, "special": 50.0},
		{"damage": 2, "range": 305.0, "attack_cooldown": 0.70, "special": 88.0},
	]
	BRANCH_A_COSTS = [75, 110]  # DMG branch: 1->2 $75, 2->3 $110
	BRANCH_B_COSTS = [75, 110]  # SPD branch: 1->2 $75, 2->3 $110
	branch_name_a = "DAMAGE"
	branch_name_b = "SPEED"
	max_level = 3
	cost = COST
	MAX_PROJECTILES = MAX_PROJECTILES_CONST
	special_id = SPECIAL_ID
	special_name = SPECIAL_NAME
	special_value = 46.0