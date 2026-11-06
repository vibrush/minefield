class_name ResultScreen
extends Control

signal rematch_pressed
signal menu_pressed

var _winner_label: Label
var _subtitle_label: Label
var _player_cards: Array[Dictionary] = []
var _rematch_button: Button
var _click_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_setup_click_audio()
	_build()

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

func _bind_click(button: Button) -> void:
	button.pressed.connect(_play_click)

func _play_click() -> void:
	if _click_player != null:
		_click_player.play()

func _build() -> void:
	var overlay := UITheme.make_overlay(Color(0.005, 0.008, 0.012, 0.9))
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UITheme.make_panel(Color(0.035, 0.048, 0.063, 0.98), UITheme.BORDER_BRIGHT)
	panel.custom_minimum_size = Vector2(760.0, 0.0)
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var kicker := UITheme.make_label("SECTOR REPORT // FINAL", 12, UITheme.MUTED)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(kicker)

	_winner_label = UITheme.make_header("MATCH COMPLETE", 42, UITheme.ACCENT)
	_winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_winner_label)

	_subtitle_label = UITheme.make_label("", 13, UITheme.MUTED)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_subtitle_label)

	layout.add_child(UITheme.make_spacer(6.0))
	layout.add_child(UITheme.make_separator(UITheme.BORDER, 1.0))
	layout.add_child(UITheme.make_spacer(10.0))

	var scoreboard := HBoxContainer.new()
	scoreboard.add_theme_constant_override("separation", 18)
	layout.add_child(scoreboard)
	for player_id in GameConfig.PLAYER_COUNT:
		var card := _make_player_card(player_id)
		scoreboard.add_child(card["panel"])
		_player_cards.append(card)

	layout.add_child(UITheme.make_spacer(12.0))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	layout.add_child(buttons)
	_rematch_button = UITheme.make_button("REMATCH", 220.0)
	_rematch_button.pressed.connect(func() -> void: rematch_pressed.emit())
	_bind_click(_rematch_button)
	buttons.add_child(_rematch_button)
	var menu_button := UITheme.make_button("MAIN MENU", 220.0, UITheme.CYAN)
	menu_button.pressed.connect(func() -> void: menu_pressed.emit())
	_bind_click(menu_button)
	buttons.add_child(menu_button)

func _make_player_card(player_id: int) -> Dictionary:
	var panel := UITheme.make_panel(
		Color(0.055, 0.072, 0.09, 0.9),
		Color(GameConfig.PLAYER_COLORS[player_id], 0.5)
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(330.0, 0.0)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)

	var name_label := UITheme.make_label(
		"P%d // %s" % [player_id + 1, GameConfig.PLAYER_NAMES[player_id]],
		15,
		GameConfig.PLAYER_COLORS[player_id]
	)
	layout.add_child(name_label)

	var score_label := UITheme.make_label("0", 46, UITheme.TEXT)
	layout.add_child(score_label)

	var detail_label := UITheme.make_label("CORRECT FLAGS", 11, UITheme.MUTED)
	layout.add_child(detail_label)

	var stat_label := UITheme.make_label("", 12, UITheme.MUTED)
	layout.add_child(stat_label)

	return {
		"panel": panel,
		"score": score_label,
		"stat": stat_label,
	}

func show_result(data: Dictionary) -> void:
	visible = true
	var winner_id: int = data.get("winner_id", -1)
	var scores: Array = data.get("scores", [0, 0])
	var difficulty: DifficultyConfig = data.get("difficulty", null)
	var stats: Array = data.get("stats", [])

	if winner_id == -1:
		_winner_label.text = "DRAW"
		_winner_label.add_theme_color_override("font_color", UITheme.CYAN)
	else:
		_winner_label.text = "PLAYER %d WINS" % (winner_id + 1)
		_winner_label.add_theme_color_override("font_color", GameConfig.PLAYER_COLORS[winner_id])

	if difficulty != null:
		_subtitle_label.text = "%s // %s // %d MINES" % [
			difficulty.display_name,
			difficulty.arena_text(),
			difficulty.bomb_count,
		]
	else:
		_subtitle_label.text = "MATCH COMPLETE"

	for player_id in _player_cards.size():
		var card := _player_cards[player_id]
		var score_label: Label = card["score"]
		var stat_label: Label = card["stat"]
		score_label.text = str(scores[player_id])
		score_label.add_theme_color_override(
			"font_color",
			GameConfig.PLAYER_COLORS[player_id] if player_id == winner_id else UITheme.TEXT
		)
		if player_id < stats.size():
			stat_label.text = "BOMBS TRIGGERED %d  //  ELIMINATIONS %d" % [
				stats[player_id].get("bombs", 0),
				stats[player_id].get("eliminations", 0),
			]
		else:
			stat_label.text = ""

	if _rematch_button != null:
		_rematch_button.grab_focus()

func hide_result() -> void:
	visible = false
