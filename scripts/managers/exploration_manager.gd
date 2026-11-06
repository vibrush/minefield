class_name ExplorationManager
extends Node

signal player_memory_changed(player_id: int)

var _safe_known: Array[PackedByteArray] = []
var _bomb_seen: Array[PackedByteArray] = []
var _tile_count := 0

func setup(tile_count: int) -> void:
	_tile_count = tile_count
	_safe_known.clear()
	_bomb_seen.clear()
	for player_id in GameConfig.PLAYER_COUNT:
		_safe_known.append(_blank_mask())
		_bomb_seen.append(_blank_mask())

func _blank_mask() -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(_tile_count)
	mask.fill(0)
	return mask

func _valid(player_id: int, index: int) -> bool:
	return player_id >= 0 and player_id < _safe_known.size() and index >= 0 and index < _tile_count

func mark_safe_revealed(player_id: int, index: int) -> bool:
	if not _valid(player_id, index):
		return false
	if _safe_known[player_id][index] == 1:
		return false
	_safe_known[player_id][index] = 1
	player_memory_changed.emit(player_id)
	return true

func mark_bomb_seen(player_id: int, index: int) -> bool:
	if not _valid(player_id, index):
		return false
	if _bomb_seen[player_id][index] == 1:
		return false
	_bomb_seen[player_id][index] = 1
	player_memory_changed.emit(player_id)
	return true

func clear_bomb_seen(player_id: int, index: int) -> void:
	if not _valid(player_id, index):
		return
	if _bomb_seen[player_id][index] == 0:
		return
	_bomb_seen[player_id][index] = 0
	player_memory_changed.emit(player_id)

func clear_all_bomb_seen(player_id: int) -> void:
	if player_id < 0 or player_id >= _bomb_seen.size():
		return
	var changed := false
	for index in _tile_count:
		if _bomb_seen[player_id][index] == 1:
			_bomb_seen[player_id][index] = 0
			changed = true
	if changed:
		player_memory_changed.emit(player_id)

func is_safe_known(player_id: int, index: int) -> bool:
	return _valid(player_id, index) and _safe_known[player_id][index] == 1

func is_bomb_seen(player_id: int, index: int) -> bool:
	return _valid(player_id, index) and _bomb_seen[player_id][index] == 1

func safe_known_mask(player_id: int) -> PackedByteArray:
	if player_id < 0 or player_id >= _safe_known.size():
		return PackedByteArray()
	return _safe_known[player_id]
