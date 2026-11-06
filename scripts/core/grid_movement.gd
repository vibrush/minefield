class_name GridMovement
extends RefCounted

static func is_cardinal(direction: Vector2i) -> bool:
	return absi(direction.x) + absi(direction.y) == 1

static func resolve(
	requests: Dictionary,
	players: Array[PlayerState],
	board: BoardModel
) -> Dictionary:
	var candidates := {}
	for player_id in requests.keys():
		if player_id < 0 or player_id >= players.size():
			continue
		var player: PlayerState = players[player_id]
		if player.is_eliminated or player.lives <= 0:
			continue
		var direction: Vector2i = requests[player_id]
		if not is_cardinal(direction):
			continue
		var target: Vector2i = player.cell + direction
		if not board.in_bounds(target):
			continue
		var other: PlayerState = players[1 - player_id]
		if not other.is_eliminated and target == other.cell:
			continue
		candidates[player_id] = target

	if candidates.size() == 2:
		if candidates[0] == candidates[1]:
			return {}
	return candidates
