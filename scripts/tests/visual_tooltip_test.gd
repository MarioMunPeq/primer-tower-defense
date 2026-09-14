extends Node

## Visual test: instantiate game, simulate hover on BasicCard, inspect tooltip

var game: Node
var tooltip: Control

func _ready() -> void:
	print("=== VISUAL TOOLTIP TEST START ===")
	game = preload("res://scenes/game.tscn").instantiate()
	add_child(game)
	
	# Wait for game to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get the tooltip node
	tooltip = game.get_node("UI/Tooltip")
	print("Tooltip node: ", tooltip)
	print("Tooltip script: ", tooltip.get_script())
	
	# Check the panel
	var panel = tooltip.get_child(0) if tooltip.get_child_count() > 0 else null
	print("Panel: ", panel)
	if panel:
		print("Panel theme_type_variation: ", panel.theme_type_variation)
		print("Panel size: ", panel.get_size())
		print("Panel custom_minimum_size: ", panel.custom_minimum_size)
	
	# Simulate hover on BasicCard (index 0)
	var shop = game.get_node("UI/TowerShop")
	var scroll = shop.get_node("VBox/ScrollContainer")
	var grid = scroll.get_node("ShopGrid")
	var basic_card = grid.get_node("BasicCard")
	print("BasicCard: ", basic_card)
	
	# Call the tooltip show function directly
	game._show_tower_card_tooltip(0)
	
	# Wait for tooltip to appear (delay is 0.4s, but test sets delay=0)
	tooltip.delay = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("Tooltip visible: ", tooltip.visible)
	print("Tooltip position: ", tooltip.position)
	
	# Inspect the panel content
	if panel:
		var box = panel.get_child(0) if panel.get_child_count() > 0 else null
		print("Box: ", box)
		if box:
			print("Box children count: ", box.get_child_count())
			for i in range(box.get_child_count()):
				var child = box.get_child(i)
				print("  Child ", i, ": ", child.name, " (", child.get_class(), ") - visible: ", child.visible)
				if child is Label:
					print("    Text: '", child.text, "' theme: ", child.theme_type_variation, " font_size: ", child.get_theme_font_size("font_size"))
				if child is HBoxContainer:
					print("    HBox children: ", child.get_child_count())
					for j in range(child.get_child_count()):
						var gc = child.get_child(j)
						print("      Grandchild ", j, ": ", gc.name, " (", gc.get_class(), ")")
						if gc is PanelContainer:
							print("        Chip theme: ", gc.theme_type_variation)
						if gc is VBoxContainer:
							for k in range(gc.get_child_count()):
								var ggc = gc.get_child(k)
								print("        VBox child ", k, ": ", ggc.name, " (", ggc.get_class(), ") text: '", ggc.text, "' theme: ", ggc.theme_type_variation if ggc is Label else "N/A")
				if child is PanelContainer and child != panel:
					print("    Divider/Extra panel: ", child.name, " theme: ", child.theme_type_variation, " size: ", child.custom_minimum_size)
	
	# Check if it has shadow
	if panel and panel.has_theme_stylebox("panel"):
		var sb = panel.get_theme_stylebox("panel")
		print("Panel StyleBox: shadow_size=", sb.shadow_size, " shadow_offset=", sb.shadow_offset, " shadow_color=", sb.shadow_color)
	
	print("=== VISUAL TOOLTIP TEST END ===")
	get_tree().quit()