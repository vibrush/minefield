class_name UITheme
extends RefCounted

const BG := Color("#070b10")
const BG_ALT := Color("#0b1118")
const PANEL := Color("#0c131b")
const PANEL_RAISED := Color("#111a24")
const BORDER := Color("#263341")
const BORDER_BRIGHT := Color("#405465")
const TEXT := Color("#dbe3eb")
const MUTED := Color("#8493a3")
const DIM := Color("#4e5c6b")
const ACCENT := Color("#ffb454")
const ACCENT_DARK := Color("#8a5b22")
const CYAN := Color("#6fe3ff")
const DANGER := Color("#ff5747")
const SUCCESS := Color("#67d892")

static func base_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 17
	return result

static func style_box(
	bg_color: Color,
	border_color: Color = Color.TRANSPARENT,
	border_width: int = 1,
	corner_radius: int = 2
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style

static func make_label(text_value: String, font_size: int = 17, color_value: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color_value)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	return label

static func make_header(text_value: String, font_size: int = 24, color_value: Color = ACCENT) -> Label:
	var label := make_label(text_value, font_size, color_value)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("outline_size", 6)
	return label

static func make_button(
	text_value: String,
	min_width: float = 280.0,
	accent_color: Color = ACCENT
) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(min_width, 48.0)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", accent_color)
	button.add_theme_color_override("font_pressed_color", BG)
	button.add_theme_color_override("font_focus_color", accent_color)
	button.add_theme_color_override("font_disabled_color", DIM)

	var normal := style_box(Color(0.035, 0.05, 0.068, 0.92), BORDER, 1, 2)
	normal.content_margin_left = 22.0
	var hover := style_box(Color(0.06, 0.082, 0.105, 0.98), accent_color, 1, 2)
	hover.content_margin_left = 22.0
	var pressed := style_box(accent_color.darkened(0.25), accent_color, 1, 2)
	pressed.content_margin_left = 22.0
	var focus := style_box(Color(0.0, 0.0, 0.0, 0.0), accent_color, 2, 2)
	focus.content_margin_left = 22.0
	var disabled := style_box(Color(0.025, 0.035, 0.045, 0.85), Color(0.16, 0.2, 0.24, 0.7), 1, 2)
	disabled.content_margin_left = 22.0

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", disabled)
	return button

static func make_small_button(text_value: String, min_width: float = 130.0) -> Button:
	var button := make_button(text_value, min_width)
	button.custom_minimum_size.y = 38.0
	button.add_theme_font_size_override("font_size", 15)
	return button

static func make_panel(color_value: Color = PANEL, border_color: Color = BORDER) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style_box(color_value, border_color, 1, 2))
	return panel

static func make_overlay(color_value: Color = Color(0.0, 0.0, 0.0, 0.76)) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.color = color_value
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return overlay

static func make_separator(color_value: Color = BORDER, thickness: float = 1.0) -> ColorRect:
	var separator := ColorRect.new()
	separator.color = color_value
	separator.custom_minimum_size = Vector2(0.0, thickness)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return separator

static func make_spacer(min_height: float = 0.0) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, min_height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer

static func add_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
