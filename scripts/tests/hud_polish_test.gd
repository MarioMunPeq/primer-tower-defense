extends Node
## Headless harness for the HUD polish round. Loads the real game scene,
## waits a few frames, then asserts the theme variations, stat icons and
## shop card states. Prints PASS/FAIL per check and quits with an exit code.

const GAME := preload("res://scenes/game.tscn")

var _failures := 0

func _ready() -> void:
	var game: Node = GAME.instantiate()
	add_child(game)
	await get_tree().create_timer(0.5).timeout
	_run_checks(game)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("  [PASS] %s" % label)
	else:
		_failures += 1
		printerr("  [FAIL] %s" % label)

func _run_checks(game: Node) -> void:
	var shop: PanelContainer = game.get_node("UI/TowerShop")
	var info: PanelContainer = game.get_node("UI/TowerInfoPanel")
	var grid: GridContainer = game.get_node("UI/TowerInfoPanel/VBox/StatsGrid")
	var upgrade: Button = game.get_node("UI/TowerInfoPanel/VBox/Actions/UpgradeButton")
	var sell: Button = game.get_node("UI/TowerInfoPanel/VBox/Actions/SellButton")

	print("== Theme variations ==")
	_check(shop.theme_type_variation == &"PanelLevel0", "TowerShop uses PanelLevel0")
	_check(info.theme_type_variation == &"SelectedPanel", "TowerInfoPanel uses SelectedPanel")
	_check(upgrade.theme_type_variation == &"PanelLevel2", "UpgradeButton uses PanelLevel2")
	_check(sell.theme_type_variation == &"PanelLevel2", "SellButton uses PanelLevel2")

	print("== Stats row icons ==")
	var dmg_icon: TextureRect = grid.get_node("StatDamageRow/StatDamageIcon")
	var rng_icon: TextureRect = grid.get_node("StatRangeRow/StatRangeIcon")
	var spd_icon: TextureRect = grid.get_node("StatSpeedRow/StatSpeedIcon")
	var cost_icon: TextureRect = grid.get_node("StatCostRow/StatCostIcon")
	_check(dmg_icon is TextureRect and dmg_icon.texture != null, "Damage row has an icon")
	_check(rng_icon is TextureRect and rng_icon.texture != null, "Range row has an icon")
	_check(spd_icon is TextureRect and spd_icon.texture != null, "Attack Speed row has an icon")
	_check(cost_icon is TextureRect and cost_icon.texture != null, "Cost row has an icon")
	_check(dmg_icon.texture.resource_path.contains("sword"), "Damage icon is sword.png")
	_check(rng_icon.texture.resource_path.contains("target"), "Range icon is target.png")
	_check(spd_icon.texture.resource_path.contains("hourglass"), "Attack Speed icon is hourglass.png")
	_check(cost_icon.texture.resource_path.contains("kenney_ui-pack"), "Cost icon is the gold star")

	print("== Special effect row + branch choice row ==")
	var sp_icon: TextureRect = grid.get_node("StatSpecialRow/StatSpecialIcon")
	var sp_label: Label = grid.get_node("StatSpecialRow/StatSpecialLabel")
	var sp_value: Label = grid.get_node("StatSpecialValue")
	_check(sp_icon is TextureRect and sp_icon.texture != null, "Special row has an icon")
	_check(sp_label is Label and sp_label.text != "", "Special row has a label")
	_check(sp_value is Label and sp_value.text != "", "Special row has a value label")
	var branch_row: HBoxContainer = info.get_node("VBox/BranchRow")
	_check(branch_row is HBoxContainer, "BranchRow exists")
	_check(branch_row.get_node("BranchAButton") is Button, "Branch A button exists")
	_check(branch_row.get_node("BranchBButton") is Button, "Branch B button exists")
	_check(not branch_row.visible, "BranchRow hidden by default (no tower selected)")

	print("== Shop card states (money=100, costs 50/75/120/100) ==")
	var cards := {
		"BasicCard": "TowerCard",      # nothing armed by default (tap-tap placements)
		"RapidCard": "TowerCard",
		"SniperCard": "TowerCardLocked",  # 120 > 100 -> candado + dim border
		"CryoCard": "TowerCard",          # 100 <= 100 -> affordable
	}
	for card_name: String in cards:
		var card: Button = game.get_node("UI/TowerShop/VBox/ScrollContainer/ShopGrid/%s" % card_name)
		_check(card.theme_type_variation == cards[card_name],
			"%s variation -> %s (got %s)" % [card_name, cards[card_name], card.theme_type_variation])
	var sniper_lock: Control = game.get_node("UI/TowerShop/VBox/ScrollContainer/ShopGrid/SniperCard/CardLock")
	_check(sniper_lock.visible, "SniperCard lock overlay visible (no funds)")
	var lock_icon: TextureRect = sniper_lock.get_node("LockIcon")
	_check(lock_icon != null and lock_icon.texture != null,
		"SniperCard lock overlay has a lock icon texture")
	_check(lock_icon.texture != null and lock_icon.texture.resource_path.contains("lock"),
		"SniperCard lock icon uses a lock asset")
	var lock_center: Vector2 = lock_icon.position + lock_icon.size / 2.0
	var lock_box_center: Vector2 = sniper_lock.size / 2.0
	_check((lock_center - lock_box_center).length() < 3.0,
		"SniperCard lock icon stays centered (Panel overlay, %.1fpx off)" % (lock_center - lock_box_center).length())

	print("== Tap-tap toggle (arm / disarm) ==")
	var basic: Button = game.get_node("UI/TowerShop/VBox/ScrollContainer/ShopGrid/BasicCard")
	basic.pressed.emit()
	_check(basic.theme_type_variation == &"TowerCardSelected"
		and game._tower_type_to_place == 0, "Pressing BasicCard arms it (toggle ON)")
	basic.pressed.emit()
	_check(basic.theme_type_variation == &"TowerCard"
		and game._tower_type_to_place == -1, "Pressing the armed card again disarms (toggle OFF)")

	print("== HUD money icon ==")
	var money_icon: TextureRect = game.get_node("UI/HUDBar/HUDTop/ResourcesPanel/HBox/MoneyIcon")
	_check(money_icon.texture != null and money_icon.texture.resource_path.contains("shoppingCart"),
		"Money icon is the shopping cart")

	print("== Tooltip structure ==")
	var tooltip: Control = game.get_node("UI/Tooltip")
	_check(tooltip != null, "Tooltip node exists")
	var panel: PanelContainer = null
	for child in tooltip.get_children():
		if child is PanelContainer:
			panel = child
			break
	_check(panel != null and panel.theme_type_variation == &"PanelLevel1",
		"Tooltip has PanelLevel1 panel")
	tooltip.delay = 0.0
	tooltip.show_stats("Basic Tower", [
		{"icon": preload("res://assets/ui/kenney_board-game-icons/PNG/Default (64px)/sword.png"),
		 "label": "Damage", "value": "1"},
		{"icon": preload("res://assets/ui/kenney_ui-pack/PNG/Yellow/Default/star.png"),
		 "label": "Cost", "value": "$50"},
	], "Descripción.")
	await get_tree().create_timer(0.2).timeout
	var box: VBoxContainer = null
	for child in panel.get_children():
		if child is VBoxContainer:
			box = child
			break
	_check(box != null and box.get_child_count() >= 4, "Tooltip built title + rows + footer")
	var rows := 0
	for child in box.get_children():
		if child is HBoxContainer:
			rows += 1
	_check(rows == 2, "Tooltip has 2 stat rows")

	if _failures == 0:
		print("ALL HUD POLISH CHECKS PASSED")
	else:
		print("%d HUD POLISH CHECKS FAILED" % _failures)
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(1 if _failures > 0 else 0)