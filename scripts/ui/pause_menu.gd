class_name PauseMenu
extends Control

signal resume_pressed
signal restart_pressed
signal menu_pressed
signal quit_pressed

var _resume_button: Button
var _click_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
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
	var overlay := UITheme.make_overlay(Color(0.01, 0.015, 0.02, 0.82))
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UITheme.make_panel(Color(0.04, 0.055, 0.072, 0.98), UITheme.BORDER_BRIGHT)
	panel.custom_minimum_size = Vector2(430.0, 0.0)
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var title := UITheme.make_header("OPERATION PAUSED", 30, UITheme.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var subtitle := UITheme.make_label("TACTICAL FEED SUSPENDED", 12, UITheme.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)

	layout.add_child(UITheme.make_spacer(10.0))
	layout.add_child(UITheme.make_separator(UITheme.BORDER, 1.0))
	layout.add_child(UITheme.make_spacer(10.0))

	_resume_button = UITheme.make_button("RESUME OPERATION", 330.0)
	_resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	_bind_click(_resume_button)
	layout.add_child(_resume_button)

	var restart := UITheme.make_button("RESTART MATCH", 330.0)
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	_bind_click(restart)
	layout.add_child(restart)

	var menu := UITheme.make_button("ABORT TO MAIN MENU", 330.0)
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	_bind_click(menu)
	layout.add_child(menu)

	var quit := UITheme.make_button("QUIT GAME", 330.0, UITheme.DANGER)
	quit.pressed.connect(func() -> void: quit_pressed.emit())
	_bind_click(quit)
	layout.add_child(quit)

	layout.add_child(UITheme.make_spacer(10.0))
	var hint := UITheme.make_label("ESC TO RESUME", 11, UITheme.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(hint)

func open() -> void:
	visible = true
	if _resume_button != null:
		_resume_button.grab_focus()

func close() -> void:
	visible = false
