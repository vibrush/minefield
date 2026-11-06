class_name RespawnManager
extends Node

signal respawn_countdown_changed(player_id: int, seconds_left: int)
signal player_respawned(player_id: int, cell: Vector2i)

var enabled := true
var respawn_delay: float = GameConfig.RESPAWN_DELAY_SECONDS
var rng := RandomNumberGenerator.new()

var _players: Array[PlayerState] = []
var _grid: GridManager
var _fog: FogOfWarManager
var _exploration: ExplorationManager
var _timers: Array[float] = []
var _reported_seconds: Array[int] = []

func setup(
	players: Array[PlayerState],
	grid: GridManager,
	fog: FogOfWarManager,
	exploration: ExplorationManager
) -> void:
	_players = players
	_grid = grid
	_fog = fog
	_exploration = exploration
	_timers.clear()
	_reported_seconds.clear()
	for player_id in GameConfig.PLAYER_COUNT:
		_timers.append(-1.0)
		_reported_seconds.append(-1)
	rng.randomize()

func schedule(player_id: int) -> void:
	if not enabled or player_id < 0 or player_id >= _players.size():
		return
	_players[player_id].is_eliminated = true
	_timers[player_id] = maxf(respawn_delay, 0.0)
	_reported_seconds[player_id] = -1
	_emit_countdown(player_id)

func tick(delta: float) -> void:
	if not enabled:
		return
	for player_id in _players.size():
		if _timers[player_id] < 0.0:
			continue
		_timers[player_id] -= delta
		if _timers[player_id] <= 0.0:
			_respawn(player_id)
		else:
			_emit_countdown(player_id)

func _process(delta: float) -> void:
	tick(delta)

func _emit_countdown(player_id: int) -> void:
	var seconds_left := maxi(1, ceili(_timers[player_id]))
	if seconds_left != _reported_seconds[player_id]:
		_reported_seconds[player_id] = seconds_left
		respawn_countdown_changed.emit(player_id, seconds_left)

func _respawn(player_id: int) -> void:
	var player: PlayerState = _players[player_id]
	var spawn_cell := find_respawn_cell(player_id)
	if spawn_cell == Vector2i(-1, -1):
		spawn_cell = player.spawn_cell

	_timers[player_id] = -1.0
	_reported_seconds[player_id] = -1
	player.cell = spawn_cell
	player.facing = _facing_toward_center(spawn_cell)
	player.lives = GameConfig.STARTING_LIVES
	player.flags_available = player.flags_total
	player.respawn_protection = GameConfig.RESPAWN_PROTECTION_REVEALS
	player.respawn_time_left = 0.0
	player.is_eliminated = false
	_exploration.clear_all_bomb_seen(player_id)
	_fog.recompute(player_id, spawn_cell)
	player_respawned.emit(player_id, spawn_cell)

func find_respawn_cell(player_id: int) -> Vector2i:
	if player_id < 0 or player_id >= _players.size() or _grid == null or _grid.board == null:
		return Vector2i(-1, -1)

	var board := _grid.board
	var opponent: PlayerState = _players[1 - player_id]
	var min_distance := float(board.columns) * GameConfig.RESPAWN_DISTANCE_RATIO

	var all_candidates: Array[Vector2i] = []
	var qualifying: Array[Vector2i] = []
	for index in board.tile_count:
		var cell := board.cell_of(index)
		if board.is_bomb(index):
			continue
		if cell == opponent.cell:
			continue
		all_candidates.append(cell)
		var distance := Vector2(cell - opponent.cell).length()
		if distance >= min_distance:
			qualifying.append(cell)

	if not qualifying.is_empty():
		return qualifying[rng.randi_range(0, qualifying.size() - 1)]
	if all_candidates.is_empty():
		return Vector2i(-1, -1)

	# Extremely dense boards can leave no safe tile at the required distance.
	# Fall back to the farthest available safe tiles so respawn can still finish.
	var farthest := all_candidates[0]
	var farthest_distance := Vector2(farthest - opponent.cell).length()
	for cell in all_candidates:
		var distance := Vector2(cell - opponent.cell).length()
		if distance > farthest_distance:
			farthest_distance = distance
			farthest = cell
	var farthest_candidates: Array[Vector2i] = []
	for cell in all_candidates:
		if is_equal_approx(Vector2(cell - opponent.cell).length(), farthest_distance):
			farthest_candidates.append(cell)
	return farthest_candidates[rng.randi_range(0, farthest_candidates.size() - 1)]

func _facing_toward_center(cell: Vector2i) -> Vector2i:
	var center := Vector2(_grid.board.columns - 1, _grid.board.rows - 1) * 0.5
	var delta := center - Vector2(cell)
	if absf(delta.x) >= absf(delta.y):
		return Vector2i.RIGHT if delta.x >= 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if delta.y >= 0.0 else Vector2i.UP
