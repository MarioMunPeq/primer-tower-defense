extends "res://scripts/towers/tower_base.gd"
## Basic Tower: balanced damage and range.

const RANGE := 180.0
const DAMAGE := 1
const ATTACK_COOLDOWN := 0.8
const COST := 50
const MAX_PROJECTILES_CONST := 8

# Values are set in the scene file (basic_tower.tscn)
# Range: 180, Damage: 1, Attack Cooldown: 0.8, Cost: 50