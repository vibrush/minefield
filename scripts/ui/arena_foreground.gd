extends Node2D

var arena_view

func _draw() -> void:
	if arena_view == null or arena_view.board == null:
		return
	_draw_target_highlight()
	_draw_flags()
	_draw_players()

func _draw_target_highlight() -> void:
	var view_id: int = arena_view.player_id
	var player: PlayerState = arena_view.players[view_id]
	if not player.is_active_for_actions():
		return

	var target: Vector2i = player.target_cell()
	if not arena_view.board.in_bounds(target):
		var center := _cell_center(player.cell) + Vector2(player.facing) * (GameConfig.TILE_SIZE * 0.5)
		var tip := center + Vector2(player.facing) * -8.0
		draw_line(center, tip, Color(UITheme.DANGER, 0.55), 2.0)
		return

	var rect := _cell_rect(target)
	var color := UITheme.ACCENT
	var index: int = arena_view.board.index_of(target)
	if arena_view.board.has_flag(index):
		color = UITheme.DANGER if arena_view.board.flag_owner(index) != view_id else UITheme.ACCENT
	elif arena_view.exploration.is_safe_known(view_id, index):
		color = UITheme.CYAN

	draw_rect(rect.grow(-2.0), Color(color, 0.10), true)
	draw_rect(rect.grow(-2.0), Color(color, 0.92), false, 2.5)
	var bracket := 9.0
	var corner_color := Color(color, 1.0)
	draw_line(rect.position + Vector2(0, bracket), rect.position, corner_color, 3.0)
	draw_line(rect.position, rect.position + Vector2(bracket, 0), corner_color, 3.0)
	draw_line(Vector2(rect.end.x, rect.position.y + bracket), Vector2(rect.end.x, rect.position.y), corner_color, 3.0)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x - bracket, rect.position.y), corner_color, 3.0)
	draw_line(Vector2(rect.position.x, rect.end.y - bracket), Vector2(rect.position.x, rect.end.y), corner_color, 3.0)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x + bracket, rect.end.y), corner_color, 3.0)
	draw_line(Vector2(rect.end.x, rect.end.y - bracket), rect.end, corner_color, 3.0)
	draw_line(rect.end, Vector2(rect.end.x - bracket, rect.end.y), corner_color, 3.0)

func _draw_flags() -> void:
	var view_id: int = arena_view.player_id
	for index in arena_view.board.tile_count:
		var owner_id: int = arena_view.board.flag_owner(index)
		if owner_id == GameConfig.FLAG_OWNER_NONE:
			continue
		var visible: bool = arena_view.fog.is_visible(view_id, index)
		if owner_id != view_id and not visible:
			continue
		var center := _cell_center(arena_view.board.cell_of(index))
		var alpha := 1.0 if visible else 0.55
		var color: Color = arena_view.players[owner_id].color
		var pole_bottom := center + Vector2(9.0, 15.0)
		var pole_top := center + Vector2(9.0, -14.0)
		draw_line(pole_bottom, pole_top, Color(0.78, 0.83, 0.87, alpha), 2.0)
		var pennant := PackedVector2Array([
			pole_top,
			pole_top + Vector2(0.0, 11.0),
			pole_top + Vector2(-15.0, 5.5),
		])
		draw_colored_polygon(pennant, Color(color, alpha))
		draw_circle(pole_bottom, 3.0, Color(0.16, 0.18, 0.2, alpha))

func _draw_players() -> void:
	var view_id: int = arena_view.player_id
	for player in arena_view.players:
		if player.is_eliminated:
			continue
		if player.id != view_id and not arena_view.fog.is_visible(view_id, arena_view.board.index_of(player.cell)):
			continue
		_draw_player(player, player.id == view_id)

func _draw_player(player: PlayerState, is_self: bool) -> void:
	var center := _cell_center(player.cell)
	var alpha := 1.0 if is_self else 0.86
	var shadow := Color(0.0, 0.0, 0.0, 0.35)
	draw_circle(center + Vector2(0.0, 8.0), 18.0, shadow)
	draw_circle(center, 18.0, Color(player.color, 0.16 * alpha))
	draw_circle(center, 14.0, Color(player.color, alpha))
	draw_circle(center, 10.0, Color(player.dark_color, alpha))
	draw_arc(center, 14.0, 0.0, TAU, 28, Color(0.02, 0.03, 0.04, alpha), 2.0)

	var direction := player.facing
	var perpendicular := Vector2(-direction.y, direction.x)
	var tip := center + Vector2(direction) * 26.0
	var base_center := center + Vector2(direction) * 12.0
	var arrow := PackedVector2Array([
		tip,
		base_center + perpendicular * 7.0,
		base_center - perpendicular * 7.0,
	])
	draw_colored_polygon(arrow, Color(player.color, alpha))

	if is_self:
		draw_arc(center, 21.0, 0.0, TAU, 32, Color(0.92, 0.96, 1.0, 0.7), 1.5)
	if player.respawn_protection > 0:
		draw_arc(center, 24.0, 0.0, TAU, 36, Color(UITheme.CYAN, 0.85), 2.0)
		draw_arc(center, 27.0, 0.0, TAU, 36, Color(UITheme.CYAN, 0.25), 1.0)

	var font := ThemeDB.fallback_font
	var text := str(player.id + 1)
	var size := 13
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var draw_pos := center + Vector2(-text_size.x * 0.5, text_size.y * 0.32)
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.95, 0.97, 1.0, alpha))

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * GameConfig.TILE_SIZE + Vector2.ONE * (GameConfig.TILE_SIZE * 0.5)

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * GameConfig.TILE_SIZE, Vector2.ONE * GameConfig.TILE_SIZE)
