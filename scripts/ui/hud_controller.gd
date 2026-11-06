class_name GameHUD
extends CanvasLayer

signal pause_resume_requested
signal pause_restart_requested
signal pause_menu_requested
signal quit_requested
signal rematch_requested
signal result_menu_requested

const PLAYER_HUD_SCENE := preload("res://scenes/ui/player_hud.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const RESULT_SCREEN_SCENE := preload("res://scenes/ui/result_screen.tscn")

var _root: Control
var _player_huds: Array[PlayerHUD] = []
var _flashes: Array[ColorRect] = []
var _announcements: Array[Label] = []
var _announcement_tweens: Array[Tween] = []
var _flash_tweens: Array[Tween] = []
var _timer_label: Label
var _timer_caption: Label
var _status_label: Label
var _difficulty_label: Label
var _arena_label: Label
var _pause_menu: PauseMenu
var _result_screen: ResultScreen
var _score_manager: ScoreManager
var _difficulty: DifficultyConfig
var _last_displayed_second := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	for player_id in GameConfig.PLAYER_COUNT:
		var flash := ColorRect.new()
		flash.color = Color(0.0, 0.0, 0.0, 0.0)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash.anchor_top = 0.0
		flash.anchor_bottom = 1.0
		flash.anchor_left = 0.0 if player_id == 0 else 0.5
		flash.anchor_right = 0.5 if player_id == 0 else 1.0
		_root.add_child(flash)
		_flashes.append(flash)
		_flash_tweens.append(null)

	var divider := ColorRect.new()
	divider.color = Color(UITheme.ACCENT, 0.32)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.anchor_left = 0.5
	divider.anchor_right = 0.5
	divider.anchor_top = 0.0
	divider.anchor_bottom = 1.0
	divider.offset_left = -1.0
	divider.offset_right = 1.0
	_root.add_child(divider)

	for player_id in GameConfig.PLAYER_COUNT:
		var hud := PLAYER_HUD_SCENE.instantiate() as PlayerHUD
		hud.anchor_top = 0.0
		hud.anchor_bottom = 0.0
		hud.offset_top = 14.0
		hud.offset_bottom = 162.0
		if player_id == 0:
			hud.anchor_left = 0.0
			hud.anchor_right = 0.0
			hud.offset_left = 14.0
			hud.offset_right = 336.0
		else:
			hud.anchor_left = 1.0
			hud.anchor_right = 1.0
			hud.offset_left = -336.0
			hud.offset_right = -14.0
		_root.add_child(hud)
		_player_huds.append(hud)

	var top_center := CenterContainer.new()
	top_center.anchor_left = 0.5
	top_center.anchor_right = 0.5
	top_center.offset_left = -230.0
	top_center.offset_right = 230.0
	top_center.offset_top = 10.0
	top_center.offset_bottom = 86.0
	top_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top_center)

	var top_panel := UITheme.make_panel(Color(0.025, 0.036, 0.048, 0.94), Color(0.24, 0.31, 0.38, 0.9))
	top_panel.custom_minimum_size = Vector2(440.0, 70.0)
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_center.add_child(top_panel)

	var top_layout := HBoxContainer.new()
	top_layout.add_theme_constant_override("separation", 18)
	top_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_panel.add_child(top_layout)

	var left_info := VBoxContainer.new()
	left_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_info.add_theme_constant_override("separation", 1)
	top_layout.add_child(left_info)
	_difficulty_label = UITheme.make_label("OPERATION // MEDIUM", 13, UITheme.ACCENT)
	left_info.add_child(_difficulty_label)
	_arena_label = UITheme.make_label("16 × 16 // 40 MINES", 10, UITheme.MUTED)
	left_info.add_child(_arena_label)

	var timer_box := VBoxContainer.new()
	timer_box.add_theme_constant_override("separation", 0)
	top_layout.add_child(timer_box)
	_timer_caption = UITheme.make_label("TIME", 9, UITheme.MUTED)
	_timer_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_box.add_child(_timer_caption)
	_timer_label = UITheme.make_label("05:00", 28, UITheme.ACCENT)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_box.add_child(_timer_label)

	var right_info := VBoxContainer.new()
	right_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_info.add_theme_constant_override("separation", 1)
	top_layout.add_child(right_info)
	var status_caption := UITheme.make_label("STATUS", 9, UITheme.MUTED)
	status_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_info.add_child(status_caption)
	_status_label = UITheme.make_label("LIVE", 13, UITheme.SUCCESS)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_info.add_child(_status_label)

	for player_id in GameConfig.PLAYER_COUNT:
		var announcement := UITheme.make_label("", 17, UITheme.TEXT)
		announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		announcement.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		announcement.mouse_filter = Control.MOUSE_FILTER_IGNORE
		announcement.anchor_top = 1.0
		announcement.anchor_bottom = 1.0
		announcement.offset_top = -160.0
		announcement.offset_bottom = -104.0
		if player_id == 0:
			announcement.anchor_left = 0.0
			announcement.anchor_right = 0.5
			announcement.offset_left = 24.0
			announcement.offset_right = -24.0
		else:
			announcement.anchor_left = 0.5
			announcement.anchor_right = 1.0
			announcement.offset_left = 24.0
			announcement.offset_right = -24.0
		announcement.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_root.add_child(announcement)
		_announcements.append(announcement)
		_announcement_tweens.append(null)

	_pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	_root.add_child(_pause_menu)
	_pause_menu.resume_pressed.connect(func() -> void: pause_resume_requested.emit())
	_pause_menu.restart_pressed.connect(func() -> void: pause_restart_requested.emit())
	_pause_menu.menu_pressed.connect(func() -> void: pause_menu_requested.emit())
	_pause_menu.quit_pressed.connect(func() -> void: quit_requested.emit())

	_result_screen = RESULT_SCREEN_SCENE.instantiate() as ResultScreen
	_root.add_child(_result_screen)
	_result_screen.rematch_pressed.connect(func() -> void: rematch_requested.emit())
	_result_screen.menu_pressed.connect(func() -> void: result_menu_requested.emit())

func setup(
	players: Array[PlayerState],
	score_manager: ScoreManager,
	difficulty: DifficultyConfig
) -> void:
	_score_manager = score_manager
	_difficulty = difficulty
	_difficulty_label.text = "OPERATION // %s" % difficulty.display_name
	_arena_label.text = "%s // %d MINES" % [difficulty.arena_text(), difficulty.bomb_count]
	for player_id in _player_huds.size():
		_player_huds[player_id].setup(players[player_id], score_manager)
	refresh_players()
	set_timer(difficulty.duration_seconds)

func refresh_players() -> void:
	if _score_manager == null:
		return
	for player_hud in _player_huds:
		player_hud.update_display(_score_manager)

func set_respawn_seconds(player_id: int, seconds_left: int) -> void:
	if player_id >= 0 and player_id < _player_huds.size():
		_player_huds[player_id].set_respawn_seconds(seconds_left)

func set_timer(remaining_seconds: float) -> void:
	if _timer_label == null:
		return
	var seconds := maxi(0, ceili(remaining_seconds))
	if seconds == _last_displayed_second:
		return
	_last_displayed_second = seconds
	var minutes := seconds / 60
	var remainder := seconds % 60
	_timer_label.text = "%02d:%02d" % [minutes, remainder]
	_timer_label.add_theme_color_override(
		"font_color",
		UITheme.DANGER if seconds <= 30 else UITheme.ACCENT
	)
	_timer_caption.add_theme_color_override(
		"font_color",
		UITheme.DANGER if seconds <= 30 else UITheme.MUTED
	)

func set_match_status(text_value: String, color_value: Color = UITheme.SUCCESS) -> void:
	_status_label.text = text_value
	_status_label.add_theme_color_override("font_color", color_value)

func announce(player_id: int, message: String, color_value: Color = UITheme.TEXT, duration: float = 1.8) -> void:
	if player_id < 0 or player_id >= _announcements.size():
		return
	var label := _announcements[player_id]
	label.text = message
	label.add_theme_color_override("font_color", color_value)
	label.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if _announcement_tweens[player_id] != null:
		_announcement_tweens[player_id].kill()
	var tween := create_tween()
	tween.tween_interval(maxf(0.1, duration - 0.55))
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	_announcement_tweens[player_id] = tween

func flash_player(player_id: int, color_value: Color = UITheme.DANGER, strength: float = 0.28) -> void:
	if player_id < 0 or player_id >= _flashes.size():
		return
	var flash := _flashes[player_id]
	flash.color = Color(color_value, strength)
	if _flash_tweens[player_id] != null:
		_flash_tweens[player_id].kill()
	var tween := create_tween()
	tween.tween_property(flash, "color", Color(color_value, 0.0), 0.5)
	_flash_tweens[player_id] = tween

func show_pause(show_value: bool) -> void:
	if _pause_menu == null:
		return
	if show_value:
		_pause_menu.open()
	else:
		_pause_menu.close()

func show_result(data: Dictionary) -> void:
	if _result_screen != null:
		_result_screen.show_result(data)

func split_half_width() -> float:
	return _root.size.x * 0.5
