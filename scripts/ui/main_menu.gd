extends Control

const MENU_SHADER := preload("res://shaders/menu_background.gdshader")

var _difficulty_overlay: Control
var _manual_overlay: Control
var _deploy_button: Button
var _difficulty_first_button: Button
var _manual_back_button: Button
var _menu_buttons: Array[Button] = []
var _click_player: AudioStreamPlayer

func _ready() -> void:
	theme = UITheme.base_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_click_audio()
	_build_background()
	_build_main_content()
	_build_difficulty_overlay()
	_build_manual_overlay()
	if _deploy_button != null:
		_deploy_button.grab_focus()

func _setup_click_audio() -> void:
	if not ResourceLoader.exists("res://assets/audio/click.wav"):
		return
	var stream: AudioStream = load("res://assets/audio/click.wav")
	if stream == null:
		return
	_click_player = AudioStreamPlayer.new()
	_click_player.stream = stream
	_click_player.volume_db = -14.0
	add_child(_click_player)

func _play_click() -> void:
	if _click_player != null:
		_click_player.play()

func _bind_click(button: Button) -> void:
	button.pressed.connect(_play_click)

func _build_background() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = MENU_SHADER
	background.material = material
	add_child(background)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.14)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

func _build_main_content() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 88)
	margin.add_theme_constant_override("margin_top", 52)
	margin.add_theme_constant_override("margin_right", 88)
	margin.add_theme_constant_override("margin_bottom", 42)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	layout.add_child(UITheme.make_spacer(24.0))

	var kicker := UITheme.make_label("LOCAL VERSUS  //  2 OPERATORS  //  ONE KEYBOARD", 12, UITheme.CYAN)
	layout.add_child(kicker)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 0)
	layout.add_child(title_row)
	var title_left := UITheme.make_label("MINE", 82, UITheme.ACCENT)
	title_left.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	title_left.add_theme_constant_override("outline_size", 10)
	title_row.add_child(title_left)
	var title_right := UITheme.make_label("FIELD", 82, UITheme.TEXT)
	title_right.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	title_right.add_theme_constant_override("outline_size", 10)
	title_row.add_child(title_right)

	var subtitle := UITheme.make_label(
		"A tactical minesweeper duel inside a smoke-choked dead sector. Read the numbers, mark the mines, and outlast the other operator.",
		15,
		UITheme.MUTED
	)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(590.0, 0.0)
	layout.add_child(subtitle)

	layout.add_child(UITheme.make_spacer(12.0))
	var accent_rule := ColorRect.new()
	accent_rule.color = Color(UITheme.ACCENT, 0.75)
	accent_rule.custom_minimum_size = Vector2(430.0, 2.0)
	accent_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	layout.add_child(accent_rule)
	layout.add_child(UITheme.make_spacer(18.0))

	var button_column := VBoxContainer.new()
	button_column.add_theme_constant_override("separation", 10)
	layout.add_child(button_column)

	_deploy_button = UITheme.make_button("DEPLOY OPERATION", 360.0)
	_deploy_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_deploy_button.pressed.connect(_open_difficulty)
	_bind_click(_deploy_button)
	button_column.add_child(_deploy_button)
	_menu_buttons.append(_deploy_button)

	var manual_button := UITheme.make_button("FIELD MANUAL", 360.0, UITheme.CYAN)
	manual_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	manual_button.pressed.connect(_open_manual)
	_bind_click(manual_button)
	button_column.add_child(manual_button)
	_menu_buttons.append(manual_button)

	var exit_button := UITheme.make_button("EXIT", 360.0, UITheme.DANGER)
	exit_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	exit_button.pressed.connect(func() -> void: get_tree().quit())
	_bind_click(exit_button)
	button_column.add_child(exit_button)
	_menu_buttons.append(exit_button)

	layout.add_child(UITheme.make_spacer(8.0))
	var focus_hint := UITheme.make_label("ENTER TO CONFIRM  //  ARROWS OR MOUSE TO NAVIGATE", 10, UITheme.DIM)
	layout.add_child(focus_hint)

	var footer := HBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -38.0
	footer.offset_bottom = -14.0
	footer.offset_left = 88.0
	footer.offset_right = -88.0
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)
	var status := UITheme.make_label("SYSTEM READY  //  SECTOR ABANDONED URBAN", 10, UITheme.DIM)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(status)
	var version := UITheme.make_label("MINEFIELD v1.1  //  GODOT 4", 10, UITheme.DIM)
	version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(version)

func _build_difficulty_overlay() -> void:
	_difficulty_overlay = Control.new()
	_difficulty_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_difficulty_overlay.visible = false
	add_child(_difficulty_overlay)

	_difficulty_overlay.add_child(UITheme.make_overlay(Color(0.008, 0.012, 0.018, 0.88)))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_difficulty_overlay.add_child(center)

	var panel := UITheme.make_panel(Color(0.035, 0.048, 0.063, 0.98), UITheme.BORDER_BRIGHT)
	panel.custom_minimum_size = Vector2(850.0, 0.0)
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	var title := UITheme.make_header("SELECT OPERATION SCALE", 30, UITheme.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var subtitle := UITheme.make_label(
		"Sector size, mine count, and match duration change the risk profile. Both operators receive one flag per mine.",
		12,
		UITheme.MUTED
	)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)
	layout.add_child(UITheme.make_spacer(8.0))
	layout.add_child(UITheme.make_separator(UITheme.BORDER, 1.0))
	layout.add_child(UITheme.make_spacer(8.0))

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	layout.add_child(cards)

	for profile in DifficultyConfig.get_all():
		var card := _make_difficulty_card(profile)
		cards.add_child(card)
		if _difficulty_first_button == null:
			_difficulty_first_button = card.get_meta("deploy_button")

	layout.add_child(UITheme.make_spacer(8.0))
	var back_row := HBoxContainer.new()
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(back_row)
	var back := UITheme.make_small_button("BACK", 170.0)
	back.pressed.connect(_close_overlays)
	_bind_click(back)
	back_row.add_child(back)

func _make_difficulty_card(profile: DifficultyConfig) -> PanelContainer:
	var card := UITheme.make_panel(Color(0.055, 0.072, 0.09, 0.94), Color(0.2, 0.26, 0.32, 0.9))
	card.custom_minimum_size = Vector2(248.0, 290.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	card.add_child(layout)

	var accent := UITheme.ACCENT
	if profile.id == &"medium":
		accent = UITheme.CYAN
	elif profile.id == &"hard":
		accent = UITheme.DANGER

	var name_label := UITheme.make_header(profile.display_name, 26, accent)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(name_label)

	var arena := UITheme.make_label(profile.arena_text() + " GRID", 13, UITheme.TEXT)
	arena.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(arena)

	layout.add_child(UITheme.make_separator(Color(0.2, 0.26, 0.32, 0.7), 1.0))

	var stats := UITheme.make_label(
		"MINES      %d\nFLAGS      %d\nTIME       %s" % [
			profile.bomb_count,
			profile.flags_per_player(),
			profile.duration_text(),
		],
		12,
		UITheme.MUTED
	)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(stats)

	var description := UITheme.make_label(profile.description, 11, UITheme.DIM)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(description)

	var deploy := UITheme.make_button("DEPLOY %s" % profile.display_name, 190.0, accent)
	deploy.custom_minimum_size.y = 42.0
	deploy.pressed.connect(_start_match.bind(profile.id))
	_bind_click(deploy)
	layout.add_child(deploy)
	card.set_meta("deploy_button", deploy)
	return card

func _build_manual_overlay() -> void:
	_manual_overlay = Control.new()
	_manual_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_manual_overlay.visible = false
	add_child(_manual_overlay)

	_manual_overlay.add_child(UITheme.make_overlay(Color(0.008, 0.012, 0.018, 0.88)))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_manual_overlay.add_child(center)

	var panel := UITheme.make_panel(Color(0.035, 0.048, 0.063, 0.98), UITheme.BORDER_BRIGHT)
	panel.custom_minimum_size = Vector2(820.0, 0.0)
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	panel.add_child(layout)

	var title := UITheme.make_header("FIELD MANUAL", 30, UITheme.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var subtitle := UITheme.make_label("TACTICAL EXPLORATION PROTOCOL", 11, UITheme.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)
	layout.add_child(UITheme.make_spacer(6.0))
	layout.add_child(UITheme.make_separator(UITheme.BORDER, 1.0))
	layout.add_child(UITheme.make_spacer(8.0))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	layout.add_child(columns)

	var p1_panel := _make_controls_panel(
		0,
		[
			["MOVE / FACE", "W A S D"],
			["REVEAL", "Q"],
			["PLACE / REMOVE FLAG", "E"],
		]
	)
	columns.add_child(p1_panel)

	var p2_panel := _make_controls_panel(
		1,
		[
			["MOVE / FACE", "ARROW KEYS"],
			["REVEAL", "."],
			["PLACE / REMOVE FLAG", "/"],
		]
	)
	columns.add_child(p2_panel)

	layout.add_child(UITheme.make_spacer(8.0))
	var rules := UITheme.make_label(
		"Hold a direction to move; tap it once to face it. You can only interact with the tile directly ahead.\n"
		+ "Revealing or stepping on a mine costs one life. Three lives, then a short respawn.\n"
		+ "Flags only score on real mines and remain on the board until their owner removes them.\n"
		+ "Vision is a 3x3 area. Safe numbers are remembered; mine sightings are not.\n"
		+ "ESC pauses the operation. A match ends when the timer reaches zero. Most correct flags wins.",
		12,
		UITheme.MUTED
	)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(rules)

	layout.add_child(UITheme.make_spacer(6.0))
	var back_row := HBoxContainer.new()
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(back_row)
	var back := UITheme.make_small_button("BACK", 170.0)
	back.pressed.connect(_close_overlays)
	_bind_click(back)
	back_row.add_child(back)
	_manual_back_button = back

func _make_controls_panel(player_id: int, rows: Array) -> PanelContainer:
	var panel := UITheme.make_panel(
		Color(0.052, 0.068, 0.086, 0.92),
		Color(GameConfig.PLAYER_COLORS[player_id], 0.45)
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)

	var title := UITheme.make_header(
		"P%d // %s" % [player_id + 1, GameConfig.PLAYER_NAMES[player_id]],
		17,
		GameConfig.PLAYER_COLORS[player_id]
	)
	layout.add_child(title)

	for row in rows:
		var line := HBoxContainer.new()
		var action := UITheme.make_label(row[0], 11, UITheme.MUTED)
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(action)
		var key := UITheme.make_label(row[1], 11, UITheme.TEXT)
		line.add_child(key)
		layout.add_child(line)
	return panel

func _open_difficulty() -> void:
	_close_overlays()
	_set_menu_focus_enabled(false)
	_difficulty_overlay.visible = true
	if _difficulty_first_button != null:
		_difficulty_first_button.grab_focus()

func _open_manual() -> void:
	_close_overlays()
	_set_menu_focus_enabled(false)
	_manual_overlay.visible = true
	if _manual_back_button != null:
		_manual_back_button.grab_focus()

func _close_overlays() -> void:
	_difficulty_overlay.visible = false
	_manual_overlay.visible = false
	_set_menu_focus_enabled(true)
	if _deploy_button != null:
		_deploy_button.grab_focus()

func _set_menu_focus_enabled(value: bool) -> void:
	for button in _menu_buttons:
		button.focus_mode = Control.FOCUS_ALL if value else Control.FOCUS_NONE

func _start_match(profile_id: StringName) -> void:
	GameSettings.selected_difficulty = profile_id
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _difficulty_overlay.visible or _manual_overlay.visible:
			_close_overlays()
			get_viewport().set_input_as_handled()
