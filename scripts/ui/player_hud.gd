class_name PlayerHUD
extends PanelContainer

var player: PlayerState
var _score := 0
var _respawn_seconds := 0

var _name_label: Label
var _status_label: Label
var _flags_label: Label
var _score_label: Label
var _position_label: Label
var _shield_label: Label
var _controls_label: Label
var _life_pips: Array[ColorRect] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UITheme.style_box(
		Color(0.035, 0.05, 0.065, 0.92),
		Color(0.16, 0.21, 0.26, 0.9),
		1,
		2
	))
	_build()

func _build() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	_name_label = UITheme.make_label("P1 // PLAYER 1", 17, GameConfig.PLAYER_COLORS[0])
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_name_label)

	_status_label = UITheme.make_label("ACTIVE", 12, UITheme.SUCCESS)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_status_label)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 14)
	layout.add_child(stats)

	var lives_caption := UITheme.make_label("LIVES", 11, UITheme.MUTED)
	stats.add_child(lives_caption)

	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 4)
	pips.alignment = BoxContainer.ALIGNMENT_BEGIN
	stats.add_child(pips)
	for pip_index in GameConfig.STARTING_LIVES:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14.0, 8.0)
		pip.color = UITheme.DANGER
		pips.add_child(pip)
		_life_pips.append(pip)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(spacer)

	_flags_label = UITheme.make_label("FLAGS 0 / 0", 12, UITheme.TEXT)
	stats.add_child(_flags_label)
	_score_label = UITheme.make_label("SCORE 0", 12, UITheme.ACCENT)
	stats.add_child(_score_label)

	var detail_row := HBoxContainer.new()
	layout.add_child(detail_row)
	_position_label = UITheme.make_label("GRID 00:00  //  FACING E", 11, UITheme.MUTED)
	_position_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(_position_label)
	_shield_label = UITheme.make_label("SHIELD", 11, UITheme.CYAN)
	_shield_label.visible = false
	detail_row.add_child(_shield_label)

	layout.add_child(UITheme.make_separator(Color(0.25, 0.31, 0.37, 0.35), 1.0))
	_controls_label = UITheme.make_label("", 10, UITheme.DIM)
	layout.add_child(_controls_label)

func setup(p_player: PlayerState, score_manager: ScoreManager) -> void:
	player = p_player
	_score = score_manager.score_for(player.id)
	add_theme_stylebox_override("panel", UITheme.style_box(
		Color(0.035, 0.05, 0.065, 0.92),
		Color(player.color, 0.45),
		1,
		2
	))
	_name_label.text = "P%d // %s" % [player.id + 1, player.display_name]
	_name_label.add_theme_color_override("font_color", player.color)
	_controls_label.text = (
		"WASD MOVE  |  Q REVEAL  |  E FLAG"
		if player.id == 0
		else "ARROWS MOVE  |  . REVEAL  |  / FLAG"
	)
	update_display(score_manager)

func update_display(score_manager: ScoreManager) -> void:
	if player == null:
		return
	_score = score_manager.score_for(player.id)
	_flags_label.text = "FLAGS %d / %d" % [player.flags_available, player.flags_total]
	_score_label.text = "SCORE %02d" % _score
	_position_label.text = "GRID %02d:%02d  //  FACING %s" % [
		player.cell.x, player.cell.y, player.facing_name()
	]
	_shield_label.visible = player.respawn_protection > 0 and not player.is_eliminated

	if player.is_eliminated:
		_status_label.text = "RESPAWNING %ds" % maxi(1, _respawn_seconds)
		_status_label.add_theme_color_override("font_color", UITheme.DANGER)
		_name_label.modulate = Color(1.0, 1.0, 1.0, 0.62)
	else:
		_status_label.text = "ACTIVE"
		_status_label.add_theme_color_override("font_color", UITheme.SUCCESS)
		_name_label.modulate = Color.WHITE

	for pip_index in _life_pips.size():
		var pip := _life_pips[pip_index]
		if pip_index < player.lives:
			pip.color = player.color if player.respawn_protection > 0 else UITheme.DANGER
		else:
			pip.color = Color(0.16, 0.19, 0.22, 0.85)

func set_respawn_seconds(seconds_left: int) -> void:
	_respawn_seconds = seconds_left
	if player != null and player.is_eliminated:
		_status_label.text = "RESPAWNING %ds" % maxi(1, seconds_left)
