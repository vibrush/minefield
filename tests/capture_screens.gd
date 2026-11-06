extends Node

var _capture_dir := ""

func _ready() -> void:
	_capture_dir = OS.get_environment("TEMP").path_join("opencode").path_join("karhutla_captures")
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	_run.call_deferred()

func _run() -> void:
	var menu_scene := load("res://scenes/main/main_menu.tscn") as PackedScene
	var menu := menu_scene.instantiate()
	get_tree().root.add_child(menu)
	await _wait_frames(4)
	await _save_viewport("main_menu")

	menu._open_difficulty()
	await _wait_frames(3)
	await _save_viewport("difficulty_select")

	menu._open_manual()
	await _wait_frames(3)
	await _save_viewport("field_manual")
	menu.queue_free()
	await get_tree().process_frame

	var game_scene := load("res://scenes/game/game.tscn") as PackedScene
	var game := game_scene.instantiate() as GameManager
	game.match_seed = 7331
	get_tree().root.add_child(game)
	await _wait_frames(4)
	await _save_viewport("game_initial")
	await _save_subviewport(game.left_view, "game_left_initial")
	await _save_subviewport(game.right_view, "game_right_initial")

	_setup_demo_board(game)
	await _wait_frames(4)
	await _save_viewport("game_inspecting")
	await _save_subviewport(game.left_view, "game_left_inspecting")
	await _save_subviewport(game.right_view, "game_right_inspecting")

	game.finish_match()
	await _wait_frames(3)
	await _save_viewport("result_screen")

	get_tree().quit(0)

func _wait_frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _save_viewport(label: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var path := _capture_dir.path_join(label + ".png")
	image.save_png(path)
	print("CAPTURE " + path)

func _save_subviewport(view: ArenaView, label: String) -> void:
	var image := view.get_viewport().get_texture().get_image()
	var path := _capture_dir.path_join(label + ".png")
	image.save_png(path)
	print("CAPTURE " + path)

func _setup_demo_board(game: GameManager) -> void:
	var board := game.grid_manager.board
	var safe_pair := _find_safe_pair(board)
	if not safe_pair.is_empty():
		var player := game.players[0]
		player.cell = safe_pair["start"]
		player.facing = safe_pair["direction"]
		game.fog_manager.recompute(0, player.cell)
		game.perform_reveal(0)
		game.left_view.snap_camera()
		game.hud.refresh_players()

	var bomb_pair := _find_bomb_pair(board)
	if not bomb_pair.is_empty():
		var player := game.players[1]
		player.cell = bomb_pair["safe"]
		player.facing = bomb_pair["direction"]
		game.fog_manager.recompute(1, player.cell)
		game.perform_flag(1)
		game.right_view.snap_camera()
		game.hud.refresh_players()

func _find_safe_pair(board: BoardModel) -> Dictionary:
	for index in board.tile_count:
		if board.is_bomb(index):
			continue
		var target := board.cell_of(index)
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var start: Vector2i = target - direction
			if not board.in_bounds(start) or board.is_bomb(board.index_of(start)):
				continue
			if board.index_of(start) == board.index_of(target):
				continue
			return {"start": start, "target": target, "direction": direction}
	return {}

func _find_bomb_pair(board: BoardModel) -> Dictionary:
	for index in board.tile_count:
		if not board.is_bomb(index):
			continue
		var bomb := board.cell_of(index)
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var safe: Vector2i = bomb - direction
			if not board.in_bounds(safe) or board.is_bomb(board.index_of(safe)):
				continue
			return {"safe": safe, "bomb": bomb, "direction": direction}
	return {}
