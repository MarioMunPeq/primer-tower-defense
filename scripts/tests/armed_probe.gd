extends Node

const GAME := preload("res://scenes/game.tscn")

var game: Node

func _ready() -> void:
	game = GAME.instantiate()
	add_child(game)
	await get_tree().create_timer(0.5).timeout
	game._set_tower_type(0)
	await get_tree().create_timer(0.5).timeout
	_inspect()
	get_tree().quit(0)

func _inspect() -> void:
	var card: Control = game.get_node("UI/ArmedInfo")
	print("ARMED card global=", card.get_global_rect())
	for child in card.get_children():
		_print_node(child, "  ")
	print("--- children of ArmedInfoBox:")
	var box: VBoxContainer = card.get_node("ArmedInfoBox")
	for child in box.get_children():
		_print_node(child, "  ")
	print("--- stats rows:")
	var stats: VBoxContainer = card.get_node("ArmedInfoBox/ArmedStats")
	for row in stats.get_children():
		_print_node(row, "   row: ")
	var cost_row := _find_cost_row(stats)
	print("--- cost row label/value: ", cost_row)
	var style: StyleBox = card.get_theme_stylebox("panel")
	print("STYLE content margins L/T/R/B = %d/%d/%d/%d" % [
		style.get_content_margin(SIDE_LEFT), style.get_content_margin(SIDE_TOP),
		style.get_content_margin(SIDE_RIGHT), style.get_content_margin(SIDE_BOTTOM)])
	print("CARD min size = ", card.get_combined_minimum_size())
	print("variation=", card.theme_type_variation, " theme_set=", card.theme != null,
		" resolved styleb=", (style as StyleBoxFlat).bg_color)
	print("card.get_theme()=", card.get_theme(), " path=",
		card.get_theme().resource_path if card.get_theme() != null else "NULL")
	var ui: Node = game.get_node("UI")
	print("UI theme local=", ui.get("theme"), " name=", ui.name)
	var has_theme_prop := false
	for p in ui.get_property_list():
		if p.name == "theme":
			has_theme_prop = true
			break
	print("UI has theme property=", has_theme_prop, " class=", (game.get_node("UI") as Object).get_class())
	var slot: Button = game.get_node("UI/TowerDock/DockBox/SlotGrid/BasicSlot")
	print("slot theme=", slot.theme, " slot_styleb=",
		slot.get_theme_stylebox("normal", "Button").resource_path if slot.get_theme() != null else "no-resolved")

func _find_cost_row(stats: VBoxContainer) -> String:
	for row in stats.get_children():
		if row is HBoxContainer and row.get_child_count() >= 3:
			var value: Label = row.get_child(2)
			if value is Label and value.text.contains("$"):
				return "%s | %s | %s" % [row.get_child(0).name, row.get_child(1).text, value.text]
	return "NOT FOUND"

func _print_node(node: Node, indent: String) -> void:
	var rect_str := ""
	var size_str := ""
	var style := ""
	if node is Control:
		var ctrl: Control = node as Control
		rect_str = str(ctrl.get_global_rect())
		size_str = str(ctrl.size)
		if ctrl is Label:
			style = " text='%s' var=%s" % [(ctrl as Label).text, ctrl.theme_type_variation]
		elif ctrl is Container:
			style = " var=%s" % ctrl.theme_type_variation
	print("%s%s rect=%s size=%s%s" % [indent, node.name, rect_str, size_str, style])