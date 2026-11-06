class_name GridManager
extends Node

signal board_generated
signal tile_changed(index: int)
signal flags_changed

var board: BoardModel
var _rng := RandomNumberGenerator.new()

func generate(difficulty: DifficultyConfig, excluded_cells: Array[Vector2i], seed_value: int = -1) -> BoardModel:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

	var bombs := BombGenerator.generate(
		difficulty.columns,
		difficulty.rows,
		difficulty.bomb_count,
		excluded_cells,
		_rng
	)
	board = BoardModel.create(difficulty.columns, difficulty.rows, bombs, _rng.seed)
	board_generated.emit()
	return board

func in_bounds(cell: Vector2i) -> bool:
	return board != null and board.in_bounds(cell)

func index_of(cell: Vector2i) -> int:
	return board.index_of(cell)

func cell_of(index: int) -> Vector2i:
	return board.cell_of(index)

func is_bomb(index: int) -> bool:
	return board.is_bomb(index)

func set_flag(index: int, owner_id: int) -> bool:
	if board == null or not board.set_flag(index, owner_id):
		return false
	tile_changed.emit(index)
	flags_changed.emit()
	return true

func clear_flag(index: int) -> int:
	var owner_id := board.clear_flag(index)
	if owner_id != GameConfig.FLAG_OWNER_NONE:
		tile_changed.emit(index)
		flags_changed.emit()
	return owner_id

func clear_flags_owned(owner_id: int) -> int:
	var removed := board.clear_flags_owned(owner_id)
	if removed > 0:
		tile_changed.emit(-1)
		flags_changed.emit()
	return removed

func flag_owner(index: int) -> int:
	return board.flag_owner(index)

func has_flag(index: int) -> bool:
	return board.has_flag(index)

func correct_flag_count(owner_id: int) -> int:
	return board.correct_flag_count(owner_id)
