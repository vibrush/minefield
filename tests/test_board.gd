extends SceneTree

var failures := 0
var checks := 0

func _init() -> void:
	print("== Minefield board tests ==")
	test_manual_corner_numbers()
	test_manual_border_numbers()
	test_bomb_generation()
	test_board_flags()
	test_bounds_helpers()
	test_determinism()

	print("Checks: %d, failures: %d" % [checks, failures])
	if failures == 0:
		print("RESULT: PASS")
	else:
		print("RESULT: FAIL")
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
		print("FAIL: " + message)
	else:
		print("ok: " + message)

func make_board(columns: int, rows: int, bomb_cells: Array[Vector2i]) -> BoardModel:
	var bombs := PackedByteArray()
	bombs.resize(columns * rows)
	bombs.fill(0)
	for cell in bomb_cells:
		bombs[cell.y * columns + cell.x] = 1
	return BoardModel.create(columns, rows, bombs, 12345)

func test_manual_corner_numbers() -> void:
	var board := make_board(3, 3, [
		Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(2, 2)
	])
	check(board.bomb_count == 4, "corner board has four bombs")
	check(board.adjacent_bomb_count(board.index_of(Vector2i(1, 1))) == 4, "center tile counts all four diagonal corner bombs")
	check(board.adjacent_bomb_count(board.index_of(Vector2i(1, 0))) == 2, "top edge counts only in-bounds neighbors")
	check(board.adjacent_bomb_count(board.index_of(Vector2i(0, 1))) == 2, "left edge counts only in-bounds neighbors")
	check(board.adjacent_bomb_count(board.index_of(Vector2i(1, 2))) == 2, "bottom edge counts only in-bounds neighbors")
	check(board.adjacent_bomb_count(board.index_of(Vector2i(2, 1))) == 2, "right edge counts only in-bounds neighbors")

func test_manual_border_numbers() -> void:
	var board := make_board(4, 4, [Vector2i(0, 0)])
	check(board.adjacent_bomb_count(board.index_of(Vector2i(0, 1))) == 1, "bomb at corner affects south neighbor")
	check(board.adjacent_bomb_count(board.index_of(Vector2i(1, 0))) == 1, "bomb at corner affects east neighbor")
	check(board.adjacent_bomb_count(board.index_of(Vector2i(1, 1))) == 1, "bomb at corner affects diagonal neighbor")
	check(board.adjacent_bomb_count(board.index_of(Vector2i(2, 2))) == 0, "distant tile has zero adjacent bombs")

func test_bomb_generation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9942
	for difficulty in DifficultyConfig.get_all():
		var excluded: Array[Vector2i] = [
			Vector2i(0, difficulty.rows / 2),
			Vector2i(difficulty.columns - 1, difficulty.rows / 2),
		]
		var bombs := BombGenerator.generate(
			difficulty.columns,
			difficulty.rows,
			difficulty.bomb_count,
			excluded,
			rng
		)
		var board := BoardModel.create(difficulty.columns, difficulty.rows, bombs, 1)
		check(board.bomb_count == difficulty.bomb_count, "%s board places configured bomb count" % difficulty.display_name)
		var generated_ok := true
		for cell in excluded:
			if board.is_bomb(board.index_of(cell)):
				generated_ok = false
		check(generated_ok, "%s board keeps spawn tiles safe" % difficulty.display_name)
		check_numbers_match_bruteforce(board, difficulty.display_name)

func check_numbers_match_bruteforce(board: BoardModel, label: String) -> void:
	var valid := true
	for index in board.tile_count:
		if board.is_bomb(index):
			continue
		var brute_count := 0
		var origin := board.cell_of(index)
		for offset in BoardModel.NEIGHBOR_OFFSETS:
			var neighbor := origin + offset
			if board.in_bounds(neighbor) and board.is_bomb(board.index_of(neighbor)):
				brute_count += 1
		if board.adjacent_bomb_count(index) != brute_count:
			valid = false
			push_error("Number mismatch at %s index %d: %d != %d" % [
				label, index, board.adjacent_bomb_count(index), brute_count
			])
			break
	check(valid, "%s adjacent numbers match brute-force count" % label)

func test_board_flags() -> void:
	var board := make_board(3, 3, [Vector2i(2, 2)])
	var index := board.index_of(Vector2i(0, 0))
	check(board.flag_owner(index) == GameConfig.FLAG_OWNER_NONE, "new tile starts unflagged")
	check(board.set_flag(index, 0), "first flag placement succeeds")
	check(board.flag_owner(index) == 0, "flag owner is stored")
	check(not board.set_flag(index, 1), "second flag on same tile is rejected")
	check(board.clear_flag(index) == 0, "owner can clear flag")
	check(board.flag_owner(index) == GameConfig.FLAG_OWNER_NONE, "tile is unflagged after clear")
	board.set_flag(board.index_of(Vector2i(2, 2)), 1)
	check(board.correct_flag_count(1) == 1, "correct flag is counted")
	check(board.correct_flag_count(0) == 0, "other player receives no score")
	check(board.clear_flags_owned(1) == 1, "owned flags can be cleared in bulk")

func test_bounds_helpers() -> void:
	var board := make_board(5, 4, [])
	check(board.in_bounds(Vector2i(0, 0)), "top-left is in bounds")
	check(board.in_bounds(Vector2i(4, 3)), "bottom-right is in bounds")
	check(not board.in_bounds(Vector2i(-1, 0)), "negative x is out of bounds")
	check(not board.in_bounds(Vector2i(0, 4)), "y at row count is out of bounds")
	check(board.index_of(Vector2i(3, 2)) == 13, "index conversion uses row-major order")
	check(board.cell_of(13) == Vector2i(3, 2), "cell conversion restores coordinates")

func test_determinism() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 777
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 777
	var bombs_a := BombGenerator.generate(10, 10, 12, [], rng_a)
	var bombs_b := BombGenerator.generate(10, 10, 12, [], rng_b)
	check(bombs_a == bombs_b, "same RNG seed produces identical bomb layout")
