extends "res://scripts/towers/tower_base.gd"
## Sniper Tower: very long range, high damage per shot, slow attack speed.
## Special: armor-piercing shots that ignore enemy damage_reduction.

const RANGE := 480.0
const DAMAGE := 4
const ATTACK_COOLDOWN := 2.0
const COST := 120
const MAX_PROJECTILES_CONST := 1

const SPECIAL_ID := "armor_pierce"
const SPECIAL_NAME := "Armor Pierce"
## Level-1 overview line used by the shop description/tooltip.
const SPECIAL_SUMMARY := "Armor Pierce"

# Level 1: Damage 4, Range 480, cooldown 2.0, armor piercing, cost $120.
# Branch A (damage): heavy single-target burst.
# Branch B (speed): fires much faster with a growing range.

func _init() -> void:
	STATS_PER_LEVEL = [
		{"damage": 4, "range": 480.0, "attack_cooldown": 2.0},
	]
	BRANCH_A_STATS = [
		{"damage": 6, "range": 520.0, "attack_cooldown": 1.9},
		{"damage": 9, "range": 560.0, "attack_cooldown": 1.8},
	]
	BRANCH_B_STATS = [
		{"damage": 5, "range": 540.0, "attack_cooldown": 1.3},
		{"damage": 6, "range": 600.0, "attack_cooldown": 1.05},
	]
	BRANCH_A_COSTS = [150, 170]  # DMG branch: 1->2 $150, 2->3 $170
	BRANCH_B_COSTS = [150, 170]  # SPD branch: 1->2 $150, 2->3 $170
	branch_name_a = "DAMAGE"
	branch_name_b = "SPEED"
	max_level = 3
	cost = COST
	MAX_PROJECTILES = MAX_PROJECTILES_CONST
	special_id = SPECIAL_ID
	special_name = SPECIAL_NAME
	armor_pierce = true