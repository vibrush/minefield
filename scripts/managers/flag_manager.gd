class_name FlagManager
extends Node

signal flag_changed(index: int, owner_id: int, placed: bool)
signal action_rejected(player_id: int, reason: StringName)

var _grid: GridManager
var _exploration: ExplorationManager
var _players: Array[PlayerState] = []

func setup(grid: GridManager, exploration: ExplorationManager, players: Array[PlayerState]) -> void:
	_grid = grid
	_exploration = exploration
	_players = players

func can_place(player_id: int, index: int) -> bool:
	if not _can_act(player_id) or not _grid.in_bounds(_grid.cell_of(index)):
		return false
	if _grid.has_flag(index):
		return false
	if _exploration.is_safe_known(player_id, index):
		return false
	if _exploration.is_bomb_seen(player_id, index):
		return false
	return _players[player_id].flags_available > 0

func toggle_flag(player_id: int, index: int) -> bool:
	if not _can_act(player_id):
		action_rejected.emit(player_id, &"cannot_act")
		return false
	if index < 0 or index >= _grid.board.tile_count:
		action_rejected.emit(player_id, &"out_of_bounds")
		return false

	var player: PlayerState = _players[player_id]
	var existing_owner := _grid.flag_owner(index)

	if existing_owner != GameConfig.FLAG_OWNER_NONE:
		if existing_owner != player_id:
			action_rejected.emit(player_id, &"enemy_flag")
			return false
		_grid.clear_flag(index)
		player.flags_available += 1
		flag_changed.emit(index, player_id, false)
		return true

	if _exploration.is_safe_known(player_id, index) or _exploration.is_bomb_seen(player_id, index):
		action_rejected.emit(player_id, &"already_revealed")
		return false
	if player.flags_available <= 0:
		action_rejected.emit(player_id, &"no_flags")
		return false

	if not _grid.set_flag(index, player_id):
		action_rejected.emit(player_id, &"tile_occupied")
		return false

	player.flags_available -= 1
	flag_changed.emit(index, player_id, true)
	return true

func remove_all_owned(player_id: int) -> int:
	var removed := _grid.clear_flags_owned(player_id)
	if removed > 0:
		flag_changed.emit(-1, player_id, false)
	return removed

func correct_count(player_id: int) -> int:
	return _grid.correct_flag_count(player_id)

func _can_act(player_id: int) -> bool:
	return player_id >= 0 and player_id < _players.size() and _players[player_id].is_active_for_actions()
