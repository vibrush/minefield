extends SceneTree

var failures := 0
var checks := 0

func _init() -> void:
	print("== Minefield rules tests ==")
	test_fog_independence()
	test_fog_clipped_at_corner()
	test_exploration_memory()
	test_flag_ownership_and_inventory()
	test_flag_rejects_revealed_tiles()
	test_scoring_and_flag_removal()
	test_health_and_respawn_protection()
	test_elimination_flow()
	test_respawn_rules()
	test_respawn_disabled_on_match_end()
	test_movement_collision()
	test_flagged_bomb_step()

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

func make_board(columns: int, rows: int, bomb_cells: Array[Vector2i] = []) -> BoardModel:
	var bombs := PackedByteArray()
	bombs.resize(columns * rows)
	bombs.fill(0)
	for cell in bomb_cells:
		bombs[cell.y * columns + cell.x] = 1
	return BoardModel.create(columns, rows, bombs, 555)

func make_context(
	columns: int = 10,
	rows: int = 10,
	bomb_cells: Array[Vector2i] = []
) -> Dictionary:
	var board := make_board(columns, rows, bomb_cells)
	var grid := GridManager.new()
	grid.board = board
	var exploration := ExplorationManager.new()
	exploration.setup(board.tile_count)
	var fog := FogOfWarManager.new()
	fog.setup(board, exploration)

	var players: Array[PlayerState] = [PlayerState.new(0), PlayerState.new(1)]
	players[0].configure_for_match(Vector2i(0, rows / 2), Vector2i.RIGHT, 3)
	players[1].configure_for_match(Vector2i(columns - 1, rows / 2), Vector2i.LEFT, 3)

	var flags := FlagManager.new()
	flags.setup(grid, exploration, players)
	var health := HealthManager.new()
	health.setup(players)
	var score := ScoreManager.new()
	score.setup(flags, players)
	var respawn := RespawnManager.new()
	respawn.setup(players, grid, fog, exploration)

	return {
		"board": board,
		"grid": grid,
		"exploration": exploration,
		"fog": fog,
		"players": players,
		"flags": flags,
		"health": health,
		"score": score,
		"respawn": respawn,
	}

func test_fog_independence() -> void:
	var context := make_context(10, 10)
	var players: Array[PlayerState] = context["players"]
	var fog: FogOfWarManager = context["fog"]
	var board: BoardModel = context["board"]
	players[0].cell = Vector2i(1, 1)
	players[1].cell = Vector2i(8, 8)
	fog.recompute(0, players[0].cell)
	fog.recompute(1, players[1].cell)

	var p1_center := board.index_of(Vector2i(1, 1))
	var p2_center := board.index_of(Vector2i(8, 8))
	check(fog.is_visible(0, p1_center), "player 1 sees their own tile")
	check(fog.is_visible(0, board.index_of(Vector2i(2, 2))), "player 1 sees a diagonal vision tile")
	check(not fog.is_visible(0, p2_center), "player 1 cannot see player 2's distant tile")
	check(not fog.is_visible(1, p1_center), "player 2 cannot see player 1's distant tile")
	check(fog.visible_indices(0).size() == 9, "central vision contains nine tiles")
	check(fog.visible_mask(0) != fog.visible_mask(1), "each player has an independent visibility mask")

func test_fog_clipped_at_corner() -> void:
	var context := make_context(10, 10)
	var fog: FogOfWarManager = context["fog"]
	fog.recompute(0, Vector2i(0, 0))
	check(fog.visible_indices(0).size() == 4, "corner vision is clipped to four tiles")

func test_exploration_memory() -> void:
	var context := make_context(10, 10, [Vector2i(3, 3)])
	var players: Array[PlayerState] = context["players"]
	var fog: FogOfWarManager = context["fog"]
	var exploration: ExplorationManager = context["exploration"]
	var board: BoardModel = context["board"]

	players[0].cell = Vector2i(2, 2)
	fog.recompute(0, players[0].cell)
	var safe_index := board.index_of(Vector2i(1, 1))
	var bomb_index := board.index_of(Vector2i(3, 3))
	exploration.mark_safe_revealed(0, safe_index)
	exploration.mark_bomb_seen(0, bomb_index)

	check(exploration.is_safe_known(0, safe_index), "revealed safe tile is stored in memory")
	check(not exploration.is_safe_known(1, safe_index), "player 2 does not inherit player 1's safe memory")
	check(exploration.is_bomb_seen(0, bomb_index), "revealed bomb is visible while in vision")

	players[0].cell = Vector2i(8, 8)
	fog.recompute(0, players[0].cell)
	check(not fog.is_visible(0, safe_index), "safe tile is hidden outside vision")
	check(exploration.is_safe_known(0, safe_index), "safe number memory persists outside vision")
	check(not exploration.is_bomb_seen(0, bomb_index), "bomb information is forgotten outside vision")

	players[0].cell = Vector2i(2, 2)
	fog.recompute(0, players[0].cell)
	check(fog.is_visible(0, safe_index), "safe tile becomes visible again on return")
	check(exploration.is_safe_known(0, safe_index), "safe number can be restored when re-entering vision")

func test_flag_ownership_and_inventory() -> void:
	var context := make_context(10, 10)
	var board: BoardModel = context["board"]
	var flags: FlagManager = context["flags"]
	var players: Array[PlayerState] = context["players"]
	var target := board.index_of(Vector2i(1, 5))
	var reasons: Array[StringName] = []
	flags.action_rejected.connect(func(_player_id: int, reason: StringName) -> void: reasons.append(reason))

	check(flags.toggle_flag(0, target), "player 1 places a flag")
	check(board.flag_owner(target) == 0, "flag stores player 1 as owner")
	check(players[0].flags_available == 2, "placing a flag consumes inventory")
	check(not flags.toggle_flag(1, target), "player 2 cannot place a second flag on the same tile")
	check(reasons.size() > 0 and reasons.back() == &"enemy_flag", "player 2 receives enemy-flag rejection")
	check(not flags.toggle_flag(1, target), "player 2 cannot remove player 1's flag")
	check(flags.toggle_flag(0, target), "player 1 removes their own flag")
	check(players[0].flags_available == 3, "removing a flag restores inventory")
	check(not board.has_flag(target), "tile is clear after owner removal")

func test_flag_rejects_revealed_tiles() -> void:
	var context := make_context(10, 10)
	var board: BoardModel = context["board"]
	var flags: FlagManager = context["flags"]
	var exploration: ExplorationManager = context["exploration"]
	var players: Array[PlayerState] = context["players"]
	var target := board.index_of(Vector2i(2, 5))
	var reasons: Array[StringName] = []
	flags.action_rejected.connect(func(_player_id: int, reason: StringName) -> void: reasons.append(reason))

	exploration.mark_safe_revealed(0, target)
	check(not flags.toggle_flag(0, target), "revealed safe tile cannot receive a flag")
	check(reasons.back() == &"already_revealed", "revealed-tile rejection reason is reported")
	players[0].flags_available = 0
	var other := board.index_of(Vector2i(3, 5))
	check(not flags.toggle_flag(0, other), "flag placement fails when inventory is empty")
	check(reasons.back() == &"no_flags", "empty-inventory rejection reason is reported")

func test_scoring_and_flag_removal() -> void:
	var context := make_context(10, 10, [Vector2i(2, 2), Vector2i(7, 7)])
	var board: BoardModel = context["board"]
	var flags: FlagManager = context["flags"]
	var score: ScoreManager = context["score"]
	var players: Array[PlayerState] = context["players"]

	flags.toggle_flag(0, board.index_of(Vector2i(2, 2)))
	flags.toggle_flag(1, board.index_of(Vector2i(3, 3)))
	check(score.score_for(0) == 1, "correct flag scores for player 1")
	check(score.score_for(1) == 0, "flag on safe tile scores zero")
	check(score.winner_id() == 0, "higher score determines winner")
	players[0].flags_available = 1
	var removed := flags.remove_all_owned(0)
	check(removed == 1, "elimination removal deletes all owned flags")
	check(score.score_for(0) == 0, "removed correct flags no longer score")
	check(not board.has_flag(board.index_of(Vector2i(2, 2))), "correct flag tile is cleared")
	check(score.winner_id() == -1, "equal scores produce a draw")

func test_health_and_respawn_protection() -> void:
	var context := make_context(10, 10)
	var health: HealthManager = context["health"]
	var players: Array[PlayerState] = context["players"]
	var protected_events: Array[int] = [0]
	var damaged_events: Array[int] = [0]
	health.player_protected.connect(func(_player_id: int, _cause: int) -> void: protected_events[0] += 1)
	health.player_damaged.connect(func(_player_id: int, _lives: int, _cause: int) -> void: damaged_events[0] += 1)

	players[0].respawn_protection = 1
	health.apply_damage(0, HealthManager.DamageCause.REVEAL_BOMB)
	check(players[0].lives == 3, "respawn protection blocks the first reveal bomb")
	check(players[0].respawn_protection == 0, "respawn protection is consumed")
	check(protected_events[0] == 1 and damaged_events[0] == 0, "protection emits its own signal")
	health.apply_damage(0, HealthManager.DamageCause.REVEAL_BOMB)
	check(players[0].lives == 2, "next reveal bomb causes damage")
	check(damaged_events[0] == 1, "damage signal fires for unprotected bomb")

	players[1].respawn_protection = 1
	health.apply_damage(1, HealthManager.DamageCause.STEP_ON_BOMB)
	check(players[1].lives == 2, "stepping on a bomb ignores respawn protection")
	check(players[1].respawn_protection == 1, "stepping does not consume reveal protection")

func test_elimination_flow() -> void:
	var context := make_context(10, 10)
	var health: HealthManager = context["health"]
	var players: Array[PlayerState] = context["players"]
	var elimination_events: Array[int] = [0]
	health.player_eliminated.connect(func(_player_id: int) -> void: elimination_events[0] += 1)

	health.apply_damage(0, HealthManager.DamageCause.REVEAL_BOMB)
	health.apply_damage(0, HealthManager.DamageCause.REVEAL_BOMB)
	health.apply_damage(0, HealthManager.DamageCause.REVEAL_BOMB)
	check(players[0].lives == 0, "three hits reduce lives to zero")
	check(players[0].is_eliminated, "zero lives marks the player eliminated")
	check(elimination_events[0] == 1, "elimination signal fires exactly once")
	health.apply_damage(0, HealthManager.DamageCause.STEP_ON_BOMB)
	check(players[0].lives == 0, "eliminated players ignore further damage")

func test_respawn_rules() -> void:
	var context := make_context(10, 10, [Vector2i(9, 5), Vector2i(9, 4)])
	var players: Array[PlayerState] = context["players"]
	var flags: FlagManager = context["flags"]
	var board: BoardModel = context["board"]
	var respawn: RespawnManager = context["respawn"]
	var grid: GridManager = context["grid"]

	players[0].cell = Vector2i(0, 5)
	players[0].lives = 0
	players[0].is_eliminated = true
	players[0].flags_available = 0
	flags.toggle_flag(1, board.index_of(Vector2i(2, 2)))
	flags.toggle_flag(1, board.index_of(Vector2i(3, 3)))
	players[1].flags_available = 1

	respawn.respawn_delay = 0.0
	respawn.schedule(0)
	respawn.tick(0.01)

	var spawn_cell: Vector2i = players[0].cell
	var distance := Vector2(spawn_cell - players[1].cell).length()
	check(not players[0].is_eliminated, "player leaves elimination after the respawn timer")
	check(players[0].lives == 3, "respawn restores three lives")
	check(players[0].respawn_protection == 1, "respawn grants one reveal protection")
	check(players[0].flags_available == players[0].flags_total, "respawn refills the flag inventory")
	check(not board.is_bomb(grid.index_of(spawn_cell)), "respawn tile is not a bomb")
	check(spawn_cell != players[1].cell, "respawn tile is not occupied by the opponent")
	check(distance >= 5.0, "respawn respects fifty percent arena width distance")
	check(flags.correct_count(0) == 0, "eliminated player has no remaining scoring flags")

func test_respawn_disabled_on_match_end() -> void:
	var context := make_context(10, 10)
	var players: Array[PlayerState] = context["players"]
	var respawn: RespawnManager = context["respawn"]
	players[0].lives = 0
	players[0].is_eliminated = true
	respawn.respawn_delay = 0.0
	respawn.schedule(0)
	respawn.enabled = false
	respawn.tick(100.0)
	check(players[0].is_eliminated, "respawn is cancelled when the match has ended")
	check(players[0].lives == 0, "cancelled respawn does not restore lives")

func test_movement_collision() -> void:
	var context := make_context(5, 5)
	var players: Array[PlayerState] = context["players"]
	var board: BoardModel = context["board"]
	players[0].cell = Vector2i(2, 2)
	players[1].cell = Vector2i(4, 2)

	var same_target := GridMovement.resolve(
		{0: Vector2i.RIGHT, 1: Vector2i.LEFT},
		players,
		board
	)
	check(same_target.is_empty(), "two players moving into the same tile are both blocked")

	players[0].cell = Vector2i(2, 2)
	players[1].cell = Vector2i(3, 2)
	var into_player := GridMovement.resolve({0: Vector2i.RIGHT}, players, board)
	check(into_player.is_empty(), "player cannot move into the opponent's occupied tile")

	players[0].cell = Vector2i(0, 0)
	players[1].cell = Vector2i(4, 4)
	var out_of_bounds := GridMovement.resolve({0: Vector2i.LEFT}, players, board)
	check(out_of_bounds.is_empty(), "movement outside the arena is rejected")
	var diagonal := GridMovement.resolve({0: Vector2i(1, 1)}, players, board)
	check(diagonal.is_empty(), "diagonal movement is rejected")

	var legal := GridMovement.resolve(
		{0: Vector2i.RIGHT, 1: Vector2i.LEFT},
		players,
		board
	)
	check(legal[0] == Vector2i(1, 0) and legal[1] == Vector2i(3, 4), "both players can move simultaneously")

	players[1].is_eliminated = true
	var blocked_by_eliminated := GridMovement.resolve({1: Vector2i.UP}, players, board)
	check(blocked_by_eliminated.is_empty(), "eliminated players cannot move")

func test_flagged_bomb_step() -> void:
	var context := make_context(5, 5, [Vector2i(1, 0)])
	var players: Array[PlayerState] = context["players"]
	var board: BoardModel = context["board"]
	var flags: FlagManager = context["flags"]
	var health: HealthManager = context["health"]
	players[0].cell = Vector2i(0, 0)
	players[1].cell = Vector2i(4, 4)
	flags.toggle_flag(1, board.index_of(Vector2i(1, 0)))
	check(board.flag_owner(board.index_of(Vector2i(1, 0))) == 1, "opponent flag is on the bomb tile")

	var resolved := GridMovement.resolve({0: Vector2i.RIGHT}, players, board)
	check(resolved.has(0), "flagged tiles remain walkable")
	if resolved.has(0):
		players[0].cell = resolved[0]
	health.apply_damage(0, HealthManager.DamageCause.STEP_ON_BOMB)
	check(players[0].lives == 2, "stepping on a flagged bomb still deals damage")
	check(board.flag_owner(board.index_of(Vector2i(1, 0))) == 1, "stepping does not remove the flag")
