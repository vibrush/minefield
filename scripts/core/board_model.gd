class_name BoardModel
extends RefCounted

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0),                   Vector2i(1, 0),
	Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1),
]

var columns: int
var rows: int
var tile_count: int
var bomb_count: int
var bombs: PackedByteArray
var numbers: PackedByteArray
var flags: PackedInt32Array
var match_seed: int

func _init(p_columns: int, p_rows: int, p_seed: int = 0) -> void:
	columns = p_columns
	rows = p_rows
	tile_count = columns * rows
	match_seed = p_seed
	bombs = PackedByteArray()
	bombs.resize(tile_count)
	bombs.fill(0)
	numbers = PackedByteArray()
	numbers.resize(tile_count)
	numbers.fill(0)
	flags = PackedInt32Array()
	flags.resize(tile_count)
	flags.fill(GameConfig.FLAG_OWNER_NONE)

static func create(p_columns: int, p_rows: int, p_bombs: PackedByteArray, p_seed: int = 0) -> BoardModel:
	var board := BoardModel.new(p_columns, p_rows, p_seed)
	if p_bombs.size() == board.tile_count:
		board.bombs = p_bombs
	board._recalculate()
	return board

func _recalculate() -> void:
	bomb_count = 0
	for index in tile_count:
		if bombs[index] == 1:
			bomb_count += 1
	numbers.fill(0)
	for index in tile_count:
		if bombs[index] == 1:
			continue
		var count := 0
		for offset in NEIGHBOR_OFFSETS:
			var neighbor := cell_of(index) + offset
			if in_bounds(neighbor) and is_bomb(index_of(neighbor)):
				count += 1
		numbers[index] = count

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows

func index_of(cell: Vector2i) -> int:
	return cell.y * columns + cell.x

func cell_of(index: int) -> Vector2i:
	return Vector2i(index % columns, index / columns)

func is_bomb(index: int) -> bool:
	return index >= 0 and index < tile_count and bombs[index] == 1

func adjacent_bomb_count(index: int) -> int:
	if index < 0 or index >= tile_count:
		return 0
	return numbers[index]

func neighbor_indices(index: int) -> Array[int]:
	var neighbors: Array[int] = []
	var origin := cell_of(index)
	for offset in NEIGHBOR_OFFSETS:
		var neighbor_cell := origin + offset
		if in_bounds(neighbor_cell):
			neighbors.append(index_of(neighbor_cell))
	return neighbors

func flag_owner(index: int) -> int:
	if index < 0 or index >= tile_count:
		return GameConfig.FLAG_OWNER_NONE
	return flags[index]

func has_flag(index: int) -> bool:
	return flag_owner(index) != GameConfig.FLAG_OWNER_NONE

func set_flag(index: int, owner_id: int) -> bool:
	if index < 0 or index >= tile_count or has_flag(index):
		return false
	flags[index] = owner_id
	return true

func clear_flag(index: int) -> int:
	if index < 0 or index >= tile_count:
		return GameConfig.FLAG_OWNER_NONE
	var owner_id := flags[index]
	flags[index] = GameConfig.FLAG_OWNER_NONE
	return owner_id

func clear_flags_owned(owner_id: int) -> int:
	var removed := 0
	for index in tile_count:
		if flags[index] == owner_id:
			flags[index] = GameConfig.FLAG_OWNER_NONE
			removed += 1
	return removed

func correct_flag_count(owner_id: int) -> int:
	var count := 0
	for index in tile_count:
		if bombs[index] == 1 and flags[index] == owner_id:
			count += 1
	return count

func total_flags_placed() -> int:
	var count := 0
	for index in tile_count:
		if flags[index] != GameConfig.FLAG_OWNER_NONE:
			count += 1
	return count
