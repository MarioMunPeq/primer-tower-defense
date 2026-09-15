extends Node

const GAME := preload("res://scenes/game.tscn")

var _fail := 0

func _ready() -> void:
	var game: Node = GAME.instantiate()
	add_child(game)
	await get_tree().create_timer(0.6).timeout

	var armed: PanelContainer = game.get_node("UI/ArmedInfo")
	_on(armed.theme != null, "ArmedInfo has a theme set (local)")
	var style: StyleBox = armed.get_theme_stylebox("panel")
	_on(style.get_content_margin(SIDE_LEFT) > 0, "ArmedInfo panel has real left content margin")
	_on(armed.get_node("ArmedInfoBox/ArmedStats").get_child_count() == 5,
		"ArmedInfo has 5 stat rows (damage/range/speed/cost/special)")
	var cost_row: HBoxContainer = armed.get_node("ArmedInfoBox/ArmedStats/StatCostRow")
	var value: Label = cost_row.get_child(2)
	_on(value.text.contains("$50"), "Cost row shows $50 in a structured row (got '%s')" % value.text)

	var frozen: PanelContainer = game.get_node("UI/TowerInfo")
	_on(frozen.theme != null, "TowerInfo has a theme set (local)")

	print("FONT PROBE RESULT: ", "PASS" if _fail == 0 else "FAIL (%d)" % _fail)
	get_tree().quit(0 if _fail == 0 else 1)

func _on(cond: bool, label: String) -> void:
	print(("  [OK] " if cond else "  [X] ") + label)
	if not cond:
		_fail += 1
