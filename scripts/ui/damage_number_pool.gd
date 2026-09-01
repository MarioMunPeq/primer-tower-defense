extends Node2D
## Pool of floating damage numbers shared by all enemies in a scene. Recycles a
## fixed set of labels so hit feedback never creates or frees nodes per shot.

const DAMAGE_NUMBER := preload("res://scenes/effects/damage_number.tscn")
const POOL_SIZE := 40

var _free: Array = []

func _ready() -> void:
	for i in POOL_SIZE:
		var n: Label = DAMAGE_NUMBER.instantiate()
		add_child(n)
		n.visible = false
		n.recycled.connect(_recycle)
		_free.append(n)

## Reuses a free label, or silently skips when the pool is saturated (keeping
## frame cost flat under heavy fire).
func spawn(amount: int, world_pos: Vector2) -> void:
	if _free.is_empty():
		return
	var n: Label = _free.pop_back()
	n.spawn(amount, world_pos)

func _recycle(n: Label) -> void:
	n.visible = false
	n.position = Vector2.ZERO
	if n.get_parent() != null:
		_free.append(n)