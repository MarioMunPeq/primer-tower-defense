extends Node

var game: Node
var tooltip: Control
var screenshot_taken: bool = false

func _ready() -> void:
	print("=== SCREENSHOT TEST START ===")
	# Run the actual game scene
	game = preload("res://scenes/game.tscn").instantiate()
	add_child(game)
	
	# Wait for game to fully initialize
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	tooltip = game.get_node("UI/Tooltip")
	tooltip.delay = 0.0
	
	# Get the BasicCard and simulate hover
	var shop = game.get_node("UI/TowerShop")
	var scroll = shop.get_node("VBox/ScrollContainer")
	var grid = scroll.get_node("ShopGrid")
	var basic_card = grid.get_node("BasicCard")
	
	# Call tooltip show directly (simulating mouse_entered)
	game._show_tower_card_tooltip(0)
	
	# Wait for tooltip to build and appear
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("Tooltip visible: ", tooltip.visible)
	print("Tooltip position: ", tooltip.position)
	
	# Take screenshot using Godot's built-in
	var img = get_viewport().get_texture().get_image()
	img.save_png("user://tooltip_screenshot.png")
	print("Screenshot saved to user://tooltip_screenshot.png")
	
	# Also try to save to project folder
	img.save_png("res://tooltip_screenshot.png")
	print("Screenshot also saved to res://tooltip_screenshot.png")
	
	screenshot_taken = true
	await get_tree().process_frame
	get_tree().quit()