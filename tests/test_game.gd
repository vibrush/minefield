extends Node

var failures := 0
var checks := 0
var game: GameManager

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("== Minefield game integration tests ==")
	var scene := load("res://scenes/game/game.tscn") as PackedScene
	if scene == null:
		print("RESULT: FAIL (game scene did not load)")
		get_tree().quit(1)
		return
	game = scene.instantiate() as GameManager
	game.match_seed = 424242
	get_tree().root.add_child(game)

	test_initial_state()
	test_initial_vision()
	test_flag_and_score_integration()
	test_reveal_protection_and_damage()
	test_simultaneous_movement()
	test_step_on_bomb()
	test_elimination_and_respawn()
	await test_keyboard_movement()
	test_pause_flow()
	test_finish_flow()

	print("Checks: %d, failures: %d" % [checks, failures])
	if failures == 0:
		print("RESULT: PASS")
	else:
		print("RESULT: FAIL")
	get_tree().quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
		print("FAIL: " + message)
	else:
		print("ok: " + message)

func find_bomb_spot() -> Dictionary:
	var board := game.grid_manager.board
	for index in board.tile_count:
		if not board.is_bomb(index):
			continue
		var bomb_cell := board.cell_of(index)
		for offset in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var safe_cell: Vector2i = bomb_cell + offset
			if not board.in_bounds(safe_cell):
				continue
			if board.is_bomb(board.index_of(safe_cell)):
				continue
			return {
				"bomb_index": index,
				"bomb_cell": bomb_cell,
				"safe_cell": safe_cell,
				"direction": bomb_cell - safe_cell,
			}
	return {}

func expected_vision_size(center: Vector2i) -> int:
	var board := game.grid_manager.board
	var count := 0
	for y in range(-GameConfig.VISION_RADIUS, GameConfig.VISION_RADIUS + 1):
		for x in range(-GameConfig.VISION_RADIUS, GameConfig.VISION_RADIUS + 1):
			if board.in_bounds(center + Vector2i(x, y)):
				count += 1
	return count

func find_safe_double_move() -> Dictionary:
	var board := game.grid_manager.board
	var candidates: Array[Dictionary] = []
	for index in board.tile_count:
		if board.is_bomb(index):
			continue
		var start := board.cell_of(index)
		for direction in [Vector2i.RIGHT, Vector2i.LEFT]:
			var target: Vector2i = start + direction
			if not board.in_bounds(target) or board.is_bomb(board.index_of(target)):
				continue
			candidates.append({"start": start, "target": target, "direction": direction})
	for first in candidates:
		for second in candidates:
			if first["start"] == second["start"]:
				continue
			if first["target"] == second["start"] or second["target"] == first["start"]:
				continue
			if first["target"] == second["target"]:
				continue
			return {"first": first, "second": second}
	return {}

func find_opponent_cell(excluded: Array[Vector2i]) -> Vector2i:
	var board := game.grid_manager.board
	for index in board.tile_count:
		if board.is_bomb(index):
			continue
		var cell := board.cell_of(index)
		if not excluded.has(cell):
			return cell
	return Vector2i(0, 0)

func place_player(player_id: int, cell: Vector2i, direction: Vector2i) -> void:
	game.players[player_id].cell = cell
	game.players[player_id].facing = direction
	game.players[player_id].is_eliminated = false
	game.fog_manager.recompute(player_id, cell)
	game._refresh_views()

func test_initial_state() -> void:
	check(game.players.size() == 2, "game creates two players")
	check(game.left_view.player_id == 0 and game.right_view.player_id == 1, "views are bound to opposite players")
	check(game.left_view.board == game.right_view.board, "both views share the same board model")
	check(game.players[0].cell == Vector2i(0, game.difficulty.rows / 2), "player 1 spawns at mid-left")
	check(game.players[1].cell == Vector2i(game.difficulty.columns - 1, game.difficulty.rows / 2), "player 2 spawns at mid-right")
	check(not game.grid_manager.is_bomb(game.grid_manager.index_of(game.players[0].cell)), "player 1 spawn is safe")
	check(not game.grid_manager.is_bomb(game.grid_manager.index_of(game.players[1].cell)), "player 2 spawn is safe")
	check(game.p1_input.player_id == 0 and game.p2_input.player_id == 1, "controllers are bound to the correct players")
	check(game.remaining_time > 0.0, "match timer is armed")
	check(game.hud._timer_label.text != "", "HUD timer is populated")
	check(game.hud._player_huds[0].player == game.players[0], "HUD shows player 1 state")
	check(game.p1_input._action_name("reveal") == &"p1_reveal", "player 1 input maps to P1 actions")
	check(game.p2_input._action_name("reveal") == &"p2_reveal", "player 2 input maps to P2 actions")
	check(game.audio_manager._players.size() == AudioManager.SOUND_FILES.size(), "all sound cues are loaded")

func test_initial_vision() -> void:
	check(
		game.fog_manager.visible_indices(0).size() == expected_vision_size(game.players[0].cell),
		"player 1 starts with vision clipped to the arena edge"
	)
	check(
		game.fog_manager.visible_indices(1).size() == expected_vision_size(game.players[1].cell),
		"player 2 starts with vision clipped to the arena edge"
	)
	check(game.fog_manager.is_visible(0, game.grid_manager.index_of(game.players[0].cell)), "player 1 sees their own tile")
	check(game.fog_manager.is_visible(1, game.grid_manager.index_of(game.players[1].cell)), "player 2 sees their own tile")
	check(not game.fog_manager.is_visible(0, game.grid_manager.index_of(game.players[1].cell)), "player 1 cannot see player 2 across the arena")

func test_flag_and_score_integration() -> void:
	var spot := find_bomb_spot()
	check(not spot.is_empty(), "test board contains a reachable bomb")
	if spot.is_empty():
		return
	game.players[0].respawn_protection = 0
	game.players[0].flags_available = game.players[0].flags_total
	place_player(0, spot["safe_cell"], spot["direction"])
	var before_flags := game.players[0].flags_available

	check(game.perform_flag(0), "player 1 can flag the tile in front")
	check(game.score_manager.score_for(0) == 1, "flagging a bomb increases the live score")
	check(game.players[0].flags_available == before_flags - 1, "flag placement consumes inventory")
	check(game.perform_flag(0), "owner can remove their own flag")
	check(game.score_manager.score_for(0) == 0, "removing a correct flag reduces the score")
	check(game.players[0].flags_available == before_flags, "removing a flag restores inventory")

func test_reveal_protection_and_damage() -> void:
	var spot := find_bomb_spot()
	check(not spot.is_empty(), "test board contains a revealable bomb")
	if spot.is_empty():
		return
	place_player(0, spot["safe_cell"], spot["direction"])
	game.players[0].lives = 3
	game.players[0].respawn_protection = 1
	var result := game.perform_reveal(0)
	check(result.get("bomb", false), "revealing a bomb reports a bomb hit")
	check(game.players[0].lives == 3, "respawn shield absorbs the first revealed bomb")
	check(game.players[0].respawn_protection == 0, "respawn shield is consumed by the reveal")
	check(game.exploration_manager.is_bomb_seen(0, spot["bomb_index"]), "revealed bomb is remembered while in vision")

	check(not game.perform_flag(0), "revealed safe/bomb tiles cannot be flagged")
	check(game.perform_reveal(0).get("bomb", false), "the same bomb can still be revealed again")
	check(game.players[0].lives == 2, "unprotected reveal removes one life")
	check(game.players[0].bombs_triggered == 1, "reveal damage is counted in match stats")

func test_simultaneous_movement() -> void:
	place_player(0, Vector2i(2, 2), Vector2i.RIGHT)
	place_player(1, Vector2i(4, 2), Vector2i.LEFT)
	var accepted := game.apply_move_requests({0: Vector2i.RIGHT, 1: Vector2i.LEFT})
	check(accepted.is_empty(), "simultaneous moves into one tile are both rejected")
	check(game.players[0].cell == Vector2i(2, 2) and game.players[1].cell == Vector2i(4, 2), "blocked players remain in place")

	var moves := find_safe_double_move()
	check(not moves.is_empty(), "test board contains two safe movement pairs")
	if moves.is_empty():
		return
	var first: Dictionary = moves["first"]
	var second: Dictionary = moves["second"]
	place_player(0, first["start"], first["direction"])
	place_player(1, second["start"], second["direction"])
	accepted = game.apply_move_requests({
		0: first["direction"],
		1: second["direction"],
	})
	check(accepted.size() == 2, "two distinct simultaneous moves are accepted")
	check(game.players[0].cell == first["target"], "player 1 moved one safe tile")
	check(game.players[1].cell == second["target"], "player 2 moved one safe tile")

func test_step_on_bomb() -> void:
	var spot := find_bomb_spot()
	check(not spot.is_empty(), "test board contains a steppable bomb")
	if spot.is_empty():
		return
	var safe_cell: Vector2i = spot["safe_cell"]
	var bomb_cell: Vector2i = spot["bomb_cell"]
	var bomb_index: int = spot["bomb_index"]
	game.players[1].cell = find_opponent_cell([safe_cell, bomb_cell])
	place_player(0, safe_cell, spot["direction"])
	game.players[0].lives = 3
	game.players[0].respawn_protection = 0
	var accepted := game.apply_move_requests({0: spot["direction"]})
	check(accepted.has(0), "movement onto the bomb tile is accepted")
	check(game.players[0].cell == bomb_cell, "player arrives on the bomb tile")
	check(game.players[0].lives == 2, "stepping on a bomb removes one life")
	check(game.players[0].bombs_triggered >= 1, "step damage is recorded")
	check(game.exploration_manager.is_bomb_seen(0, bomb_index), "stepped bomb becomes known")

func test_elimination_and_respawn() -> void:
	var spot := find_bomb_spot()
	check(not spot.is_empty(), "test board contains an elimination bomb")
	if spot.is_empty():
		return
	var safe_cell: Vector2i = spot["safe_cell"]
	var bomb_cell: Vector2i = spot["bomb_cell"]
	var bomb_index: int = spot["bomb_index"]
	game.players[1].cell = find_opponent_cell([safe_cell, bomb_cell])
	place_player(0, safe_cell, spot["direction"])
	game.players[0].lives = 1
	game.players[0].respawn_protection = 0
	game.players[0].flags_available = game.players[0].flags_total
	game.exploration_manager.clear_bomb_seen(0, bomb_index)
	game.flag_manager.toggle_flag(0, bomb_index)
	check(game.score_manager.score_for(0) == 1, "player holds a scoring flag before elimination")
	game.respawn_manager.respawn_delay = 0.0

	game.apply_move_requests({0: spot["direction"]})
	check(game.players[0].lives == 0, "lethal step reduces lives to zero")
	check(game.players[0].is_eliminated, "zero lives eliminates the player")
	check(game.score_manager.score_for(0) == 0, "elimination removes the player's scoring flags")
	check(game.players[0].flags_available == 0, "elimination empties the flag inventory")
	check(not game.p1_input.enabled, "eliminated player's controls are disabled")

	game.respawn_manager.tick(0.05)
	check(not game.players[0].is_eliminated, "respawn timer returns the player to play")
	check(game.players[0].lives == GameConfig.STARTING_LIVES, "respawn restores starting lives")
	check(game.players[0].flags_available == game.players[0].flags_total, "respawn refills flags")
	check(game.players[0].respawn_protection == 1, "respawn grants one reveal shield")
	check(game.p1_input.enabled, "respawn re-enables controls")
	check(game.left_view.player_id == 0, "left view remains bound after respawn")

func action_for_direction(direction: Vector2i) -> StringName:
	if direction == Vector2i.RIGHT:
		return &"p1_right"
	if direction == Vector2i.LEFT:
		return &"p1_left"
	if direction == Vector2i.UP:
		return &"p1_up"
	return &"p1_down"

func test_keyboard_movement() -> void:
	var moves := find_safe_double_move()
	check(not moves.is_empty(), "test board contains a safe keyboard movement lane")
	if moves.is_empty():
		return
	var first: Dictionary = moves["first"]
	var start: Vector2i = first["start"]
	var target: Vector2i = first["target"]
	var direction: Vector2i = first["direction"]
	game.players[1].cell = find_opponent_cell([start, target])
	place_player(0, start, direction)

	var hold_action := action_for_direction(direction)
	Input.action_press(hold_action)
	for _frame in 20:
		await get_tree().physics_frame
	Input.action_release(hold_action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(game.players[0].cell == target, "holding a direction moves one tile")
	check(game.players[0].facing == direction, "holding a direction keeps facing aligned")

	var tap_direction := Vector2i.DOWN if direction != Vector2i.DOWN else Vector2i.UP
	var before_tap := game.players[0].cell
	var tap_action := action_for_direction(tap_direction)
	Input.action_press(tap_action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(tap_action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(game.players[0].cell == before_tap, "a quick direction tap does not move")
	check(game.players[0].facing == tap_direction, "a quick direction tap changes facing")

func test_pause_flow() -> void:
	game._set_paused(true)
	check(get_tree().paused, "pause request pauses the scene tree")
	check(game.hud._pause_menu.visible, "pause menu is shown")
	game._set_paused(false)
	check(not get_tree().paused, "resume unpauses the scene tree")
	check(not game.hud._pause_menu.visible, "pause menu is hidden on resume")

func test_finish_flow() -> void:
	game.finish_match()
	check(game.state == GameManager.MatchState.ENDED, "finish_match ends the match")
	check(game.remaining_time == 0.0, "finish_match zeroes the timer")
	check(not game.p1_input.enabled and not game.p2_input.enabled, "match end disables both controllers")
	check(not game.respawn_manager.enabled, "match end disables respawning")
	check(game.hud._result_screen.visible, "match end shows the result screen")
	check(game.hud._status_label.text == "FINAL", "match end updates HUD status")
