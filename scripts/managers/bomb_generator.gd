class_name BombGenerator
extends RefCounted

static func generate(
	columns: int,
	rows: int,
	bomb_count: int,
	excluded_cells: Array[Vector2i],
	rng: RandomNumberGenerator
) -> PackedByteArray:
	var tile_count := columns * rows
	var excluded_lookup := {}
	for cell in excluded_cells:
		if cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows:
			excluded_lookup[cell.y * columns + cell.x] = true

	var candidates: Array[int] = []
	for index in tile_count:
		if not excluded_lookup.has(index):
			candidates.append(index)

	var result := PackedByteArray()
	result.resize(tile_count)
	result.fill(0)

	var safe_bomb_count: int = clampi(bomb_count, 0, candidates.size())
	for cursor in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, cursor)
		var temp := candidates[cursor]
		candidates[cursor] = candidates[swap_index]
		candidates[swap_index] = temp

	for pick_index in safe_bomb_count:
		result[candidates[pick_index]] = 1

	return result

static func dark_tile_variation(seed_value: int) -> float:
	var mixed := (seed_value * 1103515245 + 12345) & 0x7fffffff
	return float(mixed % 1000) / 1000.0
