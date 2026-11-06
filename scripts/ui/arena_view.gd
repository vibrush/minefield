class_name ArenaView
extends Node2D

const FOG_SHADER := preload("res://shaders/fog_of_war.gdshader")
const FOREGROUND_SCRIPT := preload("res://scripts/ui/arena_foreground.gd")
const TILE := GameConfig.TILE_SIZE
const CAMERA_VERTICAL_MARGIN := 140.0

const NUMBER_COLORS: Array[Color] = [
	Color(0.44, 0.51, 0.58),
	Color(0.44, 0.74, 1.0),
	Color(0.44, 0.9, 0.62),
	Color(1.0, 0.62, 0.36),
	Color(0.79, 0.56, 1.0),
	Color(1.0, 0.45, 0.43),
	Color(0.44, 0.89, 1.0),
	Color(0.93, 0.95, 0.97),
	Color(0.93, 0.95, 0.97),
]

var player_id := 0
var board: BoardModel
var exploration: ExplorationManager
var fog: FogOfWarManager
var players: Array[PlayerState] = []

var camera: Camera2D
var _fog_sprite: Sprite2D
var _fog_texture: ImageTexture
var _fog_image: Image
var _foreground: Node2D
var _shake_remaining := 0.0
var _shake_strength := 0.0

func _ready() -> void:
	_ensure_layers()
	set_process(true)

func _ensure_layers() -> void:
	if camera != null:
		return

	_fog_sprite = Sprite2D.new()
	_fog_sprite.centered = false
	_fog_sprite.z_index = 10
	_fog_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	material.shader = FOG_SHADER
	_fog_sprite.material = material
	add_child(_fog_sprite)

	_foreground = FOREGROUND_SCRIPT.new()
	_foreground.z_index = 20
	_foreground.arena_view = self
	add_child(_foreground)

	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 9.0
	camera.zoom = Vector2.ONE * GameConfig.CAMERA_ZOOM
	add_child(camera)
	camera.make_current()

func setup(
	p_player_id: int,
	p_board: BoardModel,
	p_exploration: ExplorationManager,
	p_fog: FogOfWarManager,
	p_players: Array[PlayerState]
) -> void:
	_ensure_layers()
	player_id = p_player_id
	board = p_board
	exploration = p_exploration
	fog = p_fog
	players = p_players
	_foreground.arena_view = self
	_fog_sprite.scale = Vector2.ONE * TILE
	_fog_sprite.material.set_shader_parameter("arena_tiles", Vector2(board.columns, board.rows))
	_configure_camera_limits()
	refresh()
	snap_camera()

func _configure_camera_limits() -> void:
	if board == null or camera == null:
		return
	var width := int(board.columns * TILE)
	var height := int(board.rows * TILE)
	camera.limit_left = -int(TILE)
	camera.limit_top = -int(CAMERA_VERTICAL_MARGIN)
	camera.limit_right = width + int(TILE)
	camera.limit_bottom = height + int(CAMERA_VERTICAL_MARGIN)
	camera.limit_smoothed = false
	camera.zoom = Vector2.ONE * GameConfig.CAMERA_ZOOM

func _process(delta: float) -> void:
	if board == null or players.is_empty() or camera == null:
		return
	var viewed_player: PlayerState = players[player_id]
	camera.position = _cell_center(viewed_player.cell)

	if _shake_remaining > 0.0:
		_shake_remaining = maxf(0.0, _shake_remaining - delta)
		var falloff := _shake_remaining / maxf(0.001, _shake_remaining + delta)
		var magnitude := _shake_strength * clampf(_shake_remaining / 0.25, 0.0, 1.0)
		camera.offset = Vector2(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude)
		) * falloff
	else:
		camera.offset = Vector2.ZERO

func refresh() -> void:
	if board == null:
		return
	_rebuild_fog_mask()
	queue_redraw()
	if _foreground != null:
		_foreground.queue_redraw()

func snap_camera() -> void:
	if camera == null or board == null or players.is_empty():
		return
	camera.position = _cell_center(players[player_id].cell)
	camera.reset_smoothing()

func trigger_damage_shake(strength: float = 7.0) -> void:
	_shake_strength = strength
	_shake_remaining = 0.3

func play_explosion(cell: Vector2i, variant: int = 0) -> void:
	var effect := ExplosionEffect.new()
	effect.setup(cell, variant)
	add_child(effect)

func _rebuild_fog_mask() -> void:
	if board == null or _fog_sprite == null:
		return
	if _fog_image == null or _fog_image.get_width() != board.columns or _fog_image.get_height() != board.rows:
		_fog_image = Image.create(board.columns, board.rows, false, Image.FORMAT_RGBA8)
		_fog_texture = ImageTexture.create_from_image(_fog_image)
		_fog_sprite.texture = _fog_texture
		_fog_sprite.material.set_shader_parameter("fog_mask", _fog_texture)

	for index in board.tile_count:
		var cell := board.cell_of(index)
		var pixel: Color
		if fog.is_visible(player_id, index):
			pixel = Color(0.0, 0.0, 0.0, 0.0)
		elif exploration.is_safe_known(player_id, index):
			pixel = Color(0.0, 1.0, 0.0, 1.0)
		else:
			pixel = Color(1.0, 0.0, 0.0, 1.0)
		_fog_image.set_pixel(cell.x, cell.y, pixel)
	_fog_texture.update(_fog_image)

func _draw() -> void:
	if board == null:
		return

	var arena_width := board.columns * TILE
	var arena_height := board.rows * TILE
	var arena_rect := Rect2(0.0, 0.0, arena_width, arena_height)

	draw_rect(Rect2(-TILE * 6, -TILE * 6, arena_width + TILE * 12, arena_height + TILE * 12), Color("#040608"))
	for line_index in range(-4, board.columns + 5):
		var x := line_index * TILE
		draw_line(Vector2(x, -TILE * 5), Vector2(x, arena_height + TILE * 5), Color(0.16, 0.2, 0.24, 0.10), 1.0)
	for line_index in range(-4, board.rows + 5):
		var y := line_index * TILE
		draw_line(Vector2(-TILE * 5, y), Vector2(arena_width + TILE * 5, y), Color(0.16, 0.2, 0.24, 0.10), 1.0)

	draw_rect(arena_rect.grow(14.0), Color("#0b0f14"), true)
	draw_rect(arena_rect.grow(7.0), Color("#151c24"), true)
	draw_rect(arena_rect, Color("#0e131a"), true)

	var viewed_player: PlayerState = players[player_id]
	for y in board.rows:
		for x in board.columns:
			var index := y * board.columns + x
			var rect := Rect2(x * TILE + 1.0, y * TILE + 1.0, TILE - 2.0, TILE - 2.0)
			var visible := fog.is_visible(player_id, index)
			if not visible:
				draw_rect(rect, Color("#080c11"), true)
				continue
			if board.is_bomb(index) and exploration.is_bomb_seen(player_id, index):
				_draw_bomb_tile(rect, index)
			elif exploration.is_safe_known(player_id, index):
				_draw_safe_tile(rect, index)
			else:
				_draw_covered_tile(rect, index)

	draw_rect(arena_rect, Color(viewed_player.color, 0.35), false, 3.0)
	draw_rect(arena_rect.grow(3.0), Color(viewed_player.color, 0.12), false, 1.0)

func _draw_covered_tile(rect: Rect2, index: int) -> void:
	var variation := BombGenerator.dark_tile_variation(index * 31 + board.match_seed)
	var base := Color("#222b34").darkened(variation * 0.10)
	draw_rect(rect, base, true)
	draw_line(rect.position + Vector2(1.0, 1.0), Vector2(rect.end.x - 1.0, rect.position.y + 1.0), Color(0.42, 0.5, 0.58, 0.10), 1.0)
	draw_line(rect.position + Vector2(1.0, 1.0), Vector2(rect.position.x + 1.0, rect.end.y - 1.0), Color(0.42, 0.5, 0.58, 0.10), 1.0)
	draw_line(Vector2(rect.position.x + 1.0, rect.end.y - 1.0), Vector2(rect.end.x - 1.0, rect.end.y - 1.0), Color(0.0, 0.0, 0.0, 0.35), 1.0)
	draw_line(Vector2(rect.end.x - 1.0, rect.position.y + 1.0), Vector2(rect.end.x - 1.0, rect.end.y - 1.0), Color(0.0, 0.0, 0.0, 0.35), 1.0)
	if variation > 0.78:
		draw_circle(rect.position + Vector2(14.0, 38.0), 1.4, Color(0.4, 0.47, 0.54, 0.24))

func _draw_safe_tile(rect: Rect2, index: int) -> void:
	draw_rect(rect, Color("#111820"), true)
	draw_rect(rect.grow(-3.0), Color("#141d26"), true)
	draw_line(Vector2(rect.position.x + 3.0, rect.end.y - 3.0), Vector2(rect.end.x - 3.0, rect.end.y - 3.0), Color(0.0, 0.0, 0.0, 0.3), 1.0)
	var number := board.adjacent_bomb_count(index)
	var center := rect.get_center()
	if number == 0:
		draw_circle(center, 2.8, Color(0.36, 0.44, 0.52, 0.72))
		return
	var font := ThemeDB.fallback_font
	var text := str(number)
	var font_size := 27
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var draw_position := Vector2(
		center.x - text_size.x * 0.5,
		center.y + text_size.y * 0.34
	)
	var color := NUMBER_COLORS[clampi(number, 0, NUMBER_COLORS.size() - 1)]
	draw_string(font, draw_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_bomb_tile(rect: Rect2, _index: int) -> void:
	draw_rect(rect, Color("#231012"), true)
	draw_rect(rect.grow(-3.0), Color("#2d1416"), true)
	draw_rect(rect, Color(1.0, 0.22, 0.16, 0.28), false, 1.0)
	var center := rect.get_center()
	draw_circle(center + Vector2(0.0, 3.0), 14.0, Color("#050708"))
	draw_circle(center + Vector2(0.0, 3.0), 11.0, Color("#1b2026"))
	draw_arc(center + Vector2(0.0, 3.0), 11.0, 0.0, TAU, 28, Color(1.0, 0.3, 0.22, 0.9), 2.0)
	draw_line(center + Vector2(5.0, -7.0), center + Vector2(12.0, -17.0), Color(0.62, 0.66, 0.7), 2.0)
	draw_circle(center + Vector2(13.0, -18.0), 3.0, Color(1.0, 0.7, 0.28))
	draw_line(center + Vector2(-6.0, -4.0), center + Vector2(-2.0, 0.0), Color(0.55, 0.6, 0.65), 1.5)
	draw_line(center + Vector2(-2.0, -6.0), center + Vector2(2.0, -2.0), Color(0.55, 0.6, 0.65), 1.5)

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2.ONE * (TILE * 0.5)
