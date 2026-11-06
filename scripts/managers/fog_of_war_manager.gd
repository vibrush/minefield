class_name FogOfWarManager
extends Node

signal vision_changed(player_id: int)

var _board: BoardModel
var _exploration: ExplorationManager
var _visible: Array[PackedByteArray] = []

func setup(board: BoardModel, exploration: ExplorationManager) -> void:
	_board = board
	_exploration = exploration
	_visible.clear()
	for player_id in GameConfig.PLAYER_COUNT:
		var mask := PackedByteArray()
		mask.resize(board.tile_count)
		mask.fill(0)
		_visible.append(mask)

func recompute(player_id: int, center: Vector2i) -> void:
	if _board == null or player_id < 0 or player_id >= GameConfig.PLAYER_COUNT:
		return

	var next_mask := PackedByteArray()
	next_mask.resize(_board.tile_count)
	next_mask.fill(0)

	for offset_y in range(-GameConfig.VISION_RADIUS, GameConfig.VISION_RADIUS + 1):
		for offset_x in range(-GameConfig.VISION_RADIUS, GameConfig.VISION_RADIUS + 1):
			var cell := center + Vector2i(offset_x, offset_y)
			if _board.in_bounds(cell):
				next_mask[_board.index_of(cell)] = 1

	var previous_mask := _visible[player_id]
	for index in _board.tile_count:
		if previous_mask[index] == 1 and next_mask[index] == 0:
			if _board.is_bomb(index) and _exploration.is_bomb_seen(player_id, index):
				_exploration.clear_bomb_seen(player_id, index)

	_visible[player_id] = next_mask
	vision_changed.emit(player_id)

func is_visible(player_id: int, index: int) -> bool:
	if player_id < 0 or player_id >= _visible.size():
		return false
	if index < 0 or index >= _visible[player_id].size():
		return false
	return _visible[player_id][index] == 1

func visible_mask(player_id: int) -> PackedByteArray:
	if player_id < 0 or player_id >= _visible.size():
		return PackedByteArray()
	return _visible[player_id]

func visible_indices(player_id: int) -> Array[int]:
	var indices: Array[int] = []
	if player_id < 0 or player_id >= _visible.size():
		return indices
	for index in _visible[player_id].size():
		if _visible[player_id][index] == 1:
			indices.append(index)
	return indices
