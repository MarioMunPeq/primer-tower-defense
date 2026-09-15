extends Node
## Headless harness for the HUD redesign round. Loads the real game scene,
## waits a few frames, then asserts the new theme variations, top bar, dock
## slot states, armed/tower info cards and compact tooltip. Prints PASS/FAIL
## per check and quits with an exit code.

const GAME := preload("res://scenes/game.tscn")
const THEME: Theme = preload("res://ui_theme.tres")

var _failures := 0

func _ready() -> void:
	var game: Node = GAME.instantiate()
	add_child(game)
	await get_tree().create_timer(0.4).timeout
	_run_checks(game)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("  [PASS] %s" % label)
	else:
		_failures += 1
		printerr("  [FAIL] %s" % label)

func _check_theme_var(var_name: String) -> void:
	_check(THEME.get_type_list().has(var_name), "theme variation '%s' exists" % var_name)

func _run_checks(game: Node) -> void:
	print("== Old HUD gone ==")
	_check(game.get_node_or_null("UI/HUDBar") == null, "no legacy HUDBar node")
	_check(game.get_node_or_null("UI/TowerShop") == null, "no legacy TowerShop node")

	print("== Top bar ==")
	var top_bar: Control = game.get_node("UI/TopBar")
	var top_box: HBoxContainer = game.get_node("UI/TopBar/TopBarBox")
	_check(top_box.offset_bottom <= 62.0, "TopBar content height <= 62 (got %.1f)" % top_box.offset_bottom)
	var money_plate: PanelContainer = game.get_node("UI/TopBar/TopBarBox/ResourcesRow/MoneyPlate")
	var money_icon: TextureRect = game.get_node("UI/TopBar/TopBarBox/ResourcesRow/MoneyPlate/MoneyContent/MoneyIcon")
	var money_label: Label = game.get_node("UI/TopBar/TopBarBox/ResourcesRow/MoneyPlate/MoneyContent/MoneyLabel")
	_check(money_plate.theme_type_variation == &"PlateMoney", "MoneyPlate uses PlateMoney")
	_check(money_icon.texture != null, "MoneyPlate has an icon")
	_check(money_label.text == "100", "MoneyLabel shows starting money (got '%s')" % money_label.text)
	var lives_plate: PanelContainer = game.get_node("UI/TopBar/TopBarBox/ResourcesRow/LivesPlate")
	var lives_icon: TextureRect = game.get_node("UI/TopBar/TopBarBox/ResourcesRow/LivesPlate/LivesContent/LivesIcon")
	var base_label: Label = game.get_node("UI/TopBar/TopBarBox/ResourcesRow/LivesPlate/LivesContent/BaseLabel")
	_check(lives_plate.theme_type_variation == &"PlateLives", "LivesPlate uses PlateLives")
	_check(lives_icon.texture != null and lives_icon.texture.resource_path.contains("suit_hearts"),
		"Lives icon is a heart asset")
	_check(base_label.text == "100", "Lives label starts at 100 (got '%s')" % base_label.text)

	print("== Wave indicator ==")
	var wave_tag: Label = game.get_node("UI/TopBar/TopBarBox/WaveInd/WaveRow/WaveTag")
	var wave_label: Label = game.get_node("UI/TopBar/TopBarBox/WaveInd/WaveRow/WaveLabel")
	var wave_state: Label = game.get_node("UI/TopBar/TopBarBox/WaveInd/WaveStateLabel")
	var wave_progress: ProgressBar = game.get_node("UI/TopBar/TopBarBox/WaveInd/EnemyProgress")
	_check(wave_tag.text == "WAVE", "WaveTag reads WAVE (got '%s')" % wave_tag.text)
	_check(wave_label.text == "1 / 10", "WaveLabel reads '1 / 10' (got '%s')" % wave_label.text)
	_check(not wave_state.text.is_empty(), "WaveStateLabel is set (got '%s')" % wave_state.text)
	_check(wave_progress is ProgressBar, "EnemyProgress is a ProgressBar")

	print("== Speed + pause ==")
	var sp1: Button = game.get_node("UI/TopBar/TopBarBox/SpeedGroup/Speed1Button")
	var sp2: Button = game.get_node("UI/TopBar/TopBarBox/SpeedGroup/Speed2Button")
	var sp3: Button = game.get_node("UI/TopBar/TopBarBox/SpeedGroup/Speed3Button")
	var pause: Button = game.get_node("UI/TopBar/TopBarBox/SpeedGroup/PauseButton")
	_check(sp1.text == "1x" and sp2.text == "2x" and sp3.text == "3x",
		"Speed buttons labelled 1x/2x/3x (got '%s','%s','%s')" % [sp1.text, sp2.text, sp3.text])
	var active_speed := int(get_tree().root.get_node("Settings").default_speed)
	var active_btn: Button = [sp1, sp2, sp3][clampi(active_speed, 1, 3) - 1]
	_check(active_btn.theme_type_variation == &"SpeedBtnActive", "Default speed button is active (SpeedBtnActive)")
	for i in range(3):
		var b: Button = [sp1, sp2, sp3][i]
		if b != active_btn:
			_check(b.theme_type_variation == &"SpeedBtn", "Speed%s uses SpeedBtn (inactive)" % (i + 1))
	_check(pause.icon != null and pause.icon.resource_path.contains("pause"),
		"PauseButton uses the pause icon asset (no text glyphs)")
	_check(pause.text == "" or pause.text.contains("\\n") == false, "PauseButton has no font-glyph text")

	print("== Dock + slot states (money=100, costs 50/75/120/100) ==")
	var dock: Control = game.get_node("UI/TowerDock")
	var grid: GridContainer = game.get_node("UI/TowerDock/DockBox/SlotGrid")
	_check(dock.get_node_or_null("DockBox/ShopHeader") != null, "ShopHeader exists in dock")
	_check(dock.get_node("DockBox/ShopHeader/ShopTitle").text == "TORRES",
		"ShopTitle reads TORRES (got '%s')" % dock.get_node("DockBox/ShopHeader/ShopTitle").text)
	_check(grid.columns == 1, "Desktop dock uses 1 column (got %d)" % grid.columns)
	var slots := {
		"BasicSlot": {"var": "TowerSlot", "price": "$50"},
		"RapidSlot": {"var": "TowerSlot", "price": "$75"},
		"SniperSlot": {"var": "TowerSlotPoor", "price": "$120"},
		"CryoSlot": {"var": "TowerSlot", "price": "$100"},
	}
	for slot_name: String in slots:
		var slot: Button = game.get_node("UI/TowerDock/DockBox/SlotGrid/%s" % slot_name)
		var price: Label = slot.get_node("SlotBox/SlotPrice")
		_check(slot.theme_type_variation == slots[slot_name]["var"],
			"%s variation -> %s (got %s)" % [slot_name, slots[slot_name]["var"], slot.theme_type_variation])
		_check(price.text == slots[slot_name]["price"],
			"%s price -> %s (got '%s')" % [slot_name, slots[slot_name]["price"], price.text])
	var sniper_sprite: TextureRect = game.get_node("UI/TowerDock/DockBox/SlotGrid/SniperSlot/SlotBox/SlotSprite")
	_check(sniper_sprite.self_modulate.r < 0.9 and sniper_sprite.self_modulate.g < 0.9,
		"Sniper sprite desaturated when unaffordable")
	_check(game.get_node("UI/TowerDock/DockBox/SlotGrid/SniperSlot/SlotLock").visible == false,
		"SlotLock hidden (unlock logic not applied yet)")

	print("== ArmedInfo defaults ==")
	var armed: PanelContainer = game.get_node("UI/ArmedInfo")
	_check(armed.theme_type_variation == &"InfoCard", "ArmedInfo uses InfoCard")
	_check(not armed.visible, "ArmedInfo hidden by default")
	_check(armed.get_node("ArmedInfoBox/ArmedDivider").theme_type_variation == &"DividerSlim",
		"ArmedInfo divider uses DividerSlim")

	print("== TowerInfo defaults ==")
	var info: PanelContainer = game.get_node("UI/TowerInfo")
	var stats_grid: VBoxContainer = game.get_node("UI/TowerInfo/TowerInfoBox/StatsGrid")
	var upgrade: Button = game.get_node("UI/TowerInfo/TowerInfoBox/ActionRow/UpgradeButton")
	var sell: Button = game.get_node("UI/TowerInfo/TowerInfoBox/ActionRow/SellButton")
	_check(info.theme_type_variation == &"InfoCard", "TowerInfo uses InfoCard")
	_check(not info.visible, "TowerInfo hidden by default")
	_check(upgrade.theme_type_variation == &"UpgradeBtn", "UpgradeButton uses UpgradeBtn")
	_check(sell.theme_type_variation == &"SellBtn", "SellButton uses SellBtn")
	_check(info.get_node("TowerInfoBox/InfoDivider").theme_type_variation == &"DividerSlim", "Info divider uses DividerSlim")
	_check(info.get_node("TowerInfoBox/BranchRow/BranchAButton") is Button, "Branch A button exists")
	_check(info.get_node("TowerInfoBox/BranchRow/BranchBButton") is Button, "Branch B button exists")
	_check(not info.get_node("TowerInfoBox/BranchRow").visible, "BranchRow hidden by default")

	print("== Stats row icons ==")
	var icon_checks := {
		"StatDamageRow/StatDamageIcon": "sword",
		"StatRangeRow/StatRangeIcon": "target",
		"StatSpeedRow/StatSpeedIcon": "hourglass",
		"StatCostRow/StatCostIcon": "star",
		"StatSpecialRow/StatSpecialIcon": "fire",
	}
	for path: String in icon_checks:
		var tex: TextureRect = stats_grid.get_node(path)
		var has_tex := tex != null and tex.texture != null
		_check(has_tex, "%s has a texture" % path)
		if has_tex:
			_check(tex.texture.resource_path.contains(icon_checks[path]),
				"%s uses an icon asset (got %s)" % [path, tex.texture.resource_path.get_file()])
	var sp_value: Label = stats_grid.get_node("StatSpecialRow/StatSpecialValue")
	_check(sp_value.text != "", "Special value populated (got '%s')" % sp_value.text)

	print("== Tap-tap toggle (arm / disarm) ==")
	var basic: Button = game.get_node("UI/TowerDock/DockBox/SlotGrid/BasicSlot")
	basic.pressed.emit()
	_check(basic.theme_type_variation == &"TowerSlotSelected"
		and game._tower_type_to_place == 0, "Pressing BasicSlot arms it (toggle ON)")
	_check(armed.visible, "ArmedInfo becomes visible when armed")
	_check(armed.get_node("ArmedInfoBox/ArmedTitle").text == "Basic Tower",
		"ArmedInfo title set (got '%s')" % armed.get_node("ArmedInfoBox/ArmedTitle").text)
	var armed_rows := 0
	var cost_found := false
	for child in armed.get_node("ArmedInfoBox/ArmedStats").get_children():
		if child is HBoxContainer:
			armed_rows += 1
			var value: Label = child.get_child(child.get_child_count() - 1)
			if value is Label and value.text.contains("$50"):
				cost_found = true
	_check(armed_rows == 5, "ArmedInfo shows 5 stat rows (got %d)" % armed_rows)
	_check(cost_found, "ArmedInfo cost row shows $50")
	_check(not armed.has_node("ArmedInfoBox/ArmedCost"), "ArmedInfo cost is a stat row, not a lone label")
	_check(basic.scale.x > 1.02 and basic.scale.y > 1.02, "Selected slot is slightly scaled up")
	basic.pressed.emit()
	_check(basic.theme_type_variation == &"TowerSlot"
		and game._tower_type_to_place == -1, "Pressing the armed slot again disarms (toggle OFF)")

	print("== Tooltip (compact) ==")
	var tooltip: Control = game.get_node("UI/Tooltip")
	tooltip.delay = 0.0
	tooltip.show_stats("Basic Tower", [
		{"icon": preload("res://assets/ui/kenney_board-game-icons/PNG/Default (64px)/sword.png"),
		 "label": "Damage", "value": "1"},
		{"icon": preload("res://assets/ui/kenney_ui-pack/PNG/Yellow/Default/star.png"),
		 "label": "Cost", "value": "$50"},
	], "Ataque equilibrado a corto alcance.")
	await get_tree().create_timer(0.2).timeout
	_check(tooltip.visible, "Tooltip visible after show_stats")
	var panel: PanelContainer = null
	for child in tooltip.get_children():
		if child is PanelContainer:
			panel = child
			break
	_check(panel != null and panel.theme_type_variation == &"TooltipPanel", "Tooltip panel uses TooltipPanel")
	if panel:
		_check(panel.custom_minimum_size.x <= 230.0,
			"Tooltip stays within MAX_WIDTH (got %.1f)" % panel.custom_minimum_size.x)
	var rows := 0
	var dividers := 0
	var box: VBoxContainer = null
	if panel:
		for child in panel.get_children():
			if child is VBoxContainer:
				box = child
	if box:
		for child in box.get_children():
			if child is HBoxContainer:
				rows += 1
			if child is PanelContainer:
				dividers += 1
	_check(box != null and box.get_child_count() >= 4, "Tooltip built title + rows + divider + footer")
	_check(rows == 2, "Tooltip has 2 stat rows (got %d)" % rows)
	_check(dividers == 1, "Tooltip has 1 slim divider (got %d)" % dividers)

	print("== Theme variations ==")
	for v in ["PlateMoney", "PlateLives", "SpeedBtn", "SpeedBtnActive", "TowerSlot",
		"TowerSlotSelected", "TowerSlotPoor", "TowerSlotLocked", "LockOverlay", "InfoCard",
		"DividerSlim", "TooltipPanel", "UpgradeBtn", "SellBtn", "EndPanel", "MenuPrimaryButton",
		"MenuBtn", "speed", "res_money", "res_lives", "wave_tag", "wave_num", "wave_state",
		"shop_title", "slot_price", "slot_price_off", "info_title", "info_sub",
		"stat_label", "stat_value", "tooltip_title", "tooltip_desc", "tooltip_stat_label",
		"tooltip_stat_value", "title", "subtitle", "body"]:
		_check_theme_var(v)

	if _failures == 0:
		print("ALL HUD REDESIGN CHECKS PASSED")
	else:
		print("%d HUD REDESIGN CHECKS FAILED" % _failures)
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(1 if _failures > 0 else 0)