extends Node

var game: Node
var tooltip: Control
var shop_desc: PanelContainer

func _ready() -> void:
	print("=== BOTH PANELS TEST START ===")
	game = preload("res://scenes/game.tscn").instantiate()
	add_child(game)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	tooltip = game.get_node("UI/Tooltip")
	tooltip.delay = 0.0
	
	shop_desc = game.get_node("UI/TowerShop/VBox/ShopDesc")
	
	# Test 1: Hover BasicCard (tooltip)
	print("\n--- TEST 1: Tooltip on BasicCard hover ---")
	game._show_tower_card_tooltip(0)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("Tooltip visible: ", tooltip.visible)
	print("Tooltip position: ", tooltip.position)
	_inspect_tooltip(tooltip)
	
	# Test 2: Arm BasicCard (ShopDesc)
	print("\n--- TEST 2: ShopDesc on BasicCard armed ---")
	var shop = game.get_node("UI/TowerShop")
	var scroll = shop.get_node("VBox/ScrollContainer")
	var grid = scroll.get_node("ShopGrid")
	var basic_card = grid.get_node("BasicCard")
	basic_card.pressed.emit()  # Arm the card
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("ShopDesc visible: ", shop_desc.visible)
	_inspect_shop_desc(shop_desc)
	
	# Test 3: Switch to Cryo (Sniper)
	print("\n--- TEST 3: Switch to CryoCard (index 3) ---")
	var cryo_card = grid.get_node("CryoCard")
	cryo_card.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("ShopDesc visible: ", shop_desc.visible)
	_inspect_shop_desc(shop_desc)
	
	print("\n=== BOTH PANELS TEST END ===")
	get_tree().quit()

func _inspect_tooltip(t):
	var panel = t.get_child(0) if t.get_child_count() > 0 else null
	if not panel: return
	var box = panel.get_child(0) if panel.get_child_count() > 0 else null
	if not box: return
	print("  Tooltip panel theme: ", panel.theme_type_variation)
	print("  Tooltip box children: ", box.get_child_count())
	for i in range(box.get_child_count()):
		var child = box.get_child(i)
		print("    Child ", i, ": ", child.name, " (", child.get_class(), ") visible: ", child.visible)
		if child is Label:
			print("      Text: '", child.text, "' theme: ", child.theme_type_variation, " font_size: ", child.get_theme_font_size("font_size"))
		if child is HBoxContainer:
			print("      HBox children: ", child.get_child_count())
			for j in range(child.get_child_count()):
				var gc = child.get_child(j)
				print("        Grandchild ", j, ": ", gc.name, " (", gc.get_class(), ")")
				if gc is PanelContainer:
					print("          Chip theme: ", gc.theme_type_variation)
				if gc is VBoxContainer:
					for k in range(gc.get_child_count()):
						var ggc = gc.get_child(k)
						print("          VBox child ", k, ": ", ggc.name, " text: '", ggc.text, "' theme: ", ggc.theme_type_variation if ggc is Label else "N/A")

func _inspect_shop_desc(sd):
	if not sd.visible:
		print("  ShopDesc: NOT VISIBLE")
		return
	var box = sd.get_node("ShopDescBox")
	print("  ShopDesc panel theme: ", sd.theme_type_variation)
	print("  ShopDesc box children: ", box.get_child_count())
	for i in range(box.get_child_count()):
		var child = box.get_child(i)
		print("    Child ", i, ": ", child.name, " (", child.get_class(), ") visible: ", child.visible)
		if child is Label:
			print("      Text: '", child.text, "' theme: ", child.theme_type_variation, " font_size: ", child.get_theme_font_size("font_size"))
		if child is HBoxContainer and child.visible:
			print("      HBox children: ", child.get_child_count())
			for j in range(child.get_child_count()):
				var gc = child.get_child(j)
				print("        Grandchild ", j, ": ", gc.name, " (", gc.get_class(), ")")
				if gc is PanelContainer:
					print("          Chip theme: ", gc.theme_type_variation)
				if gc is VBoxContainer:
					for k in range(gc.get_child_count()):
						var ggc = gc.get_child(k)
						print("          VBox child ", k, ": ", ggc.name, " text: '", ggc.text, "' theme: ", ggc.theme_type_variation if ggc is Label else "N/A")