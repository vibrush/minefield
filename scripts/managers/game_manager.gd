class_name GameManager
extends Control

enum MatchState {
	PLAYING,
	ENDED,
}

@export var match_seed: int = -1

@onready var left_view: ArenaView = $SplitScreen/LeftFrame/LeftViewport/Arena
@onready var right_view: ArenaView = $SplitScreen/RightFrame/RightViewport/Arena
@onready var grid_manager: GridManager = $Managers/GridManager
@onready var exploration_manager: ExplorationManager = $Managers/ExplorationManager
@onready var fog_manager: FogOfWarManager = $Managers/FogOfWarManager
@onready var flag_manager: FlagManager = $Managers/FlagManager
@onready var health_manager: HealthManager = $Managers/HealthManager
@onready var respawn_manager: RespawnManager = $Managers/RespawnManager
@onready var score_manager: ScoreManager = $Managers/ScoreManager
@onready var audio_manager: AudioManager = $Managers/AudioManager
@onready var p1_input: PlayerController = $Managers/Player1Input
@onready var p2_input: PlayerController = $Managers/Player2Input
@onready var hud: GameHUD = $HUD

var difficulty: DifficultyConfig
var players: Array[PlayerState] = []
var remaining_time := 0.0
var state: MatchState = MatchState.PLAYING

var _pending_moves := {}
var _pending_actions: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100
	get_tree().paused = false
	_start_match()

func _start_match() -> void:
	difficulty = GameSettings.get_difficulty()
	var mid_row := difficulty.rows / 2
	var spawn_1 := Vector2i(0, mid_row)
	var spawn_2 := Vector2i(difficulty.columns - 1, mid_row)

	players = [PlayerState.new(0), PlayerState.new(1)]
	players[0].configure_for_match(spawn_1, Vector2i.RIGHT, difficulty.flags_per_player())
	players[1].configure_for_match(spawn_2, Vector2i.LEFT, difficulty.flags_per_player())

	grid_manager.generate(difficulty, [spawn_1, spawn_2], match_seed)
	var board := grid_manager.board
	exploration_manager.setup(board.tile_count)
	fog_manager.setup(board, exploration_manager)
	flag_manager.setup(grid_manager, exploration_manager, players)
	health_manager.setup(players)
	respawn_manager.setup(players, grid_manager, fog_manager, exploration_manager)
	score_manager.setup(flag_manager, players)

	fog_manager.recompute(0, players[0].cell)
	fog_manager.recompute(1, players[1].cell)

	left_view.setup(0, board, exploration_manager, fog_manager, players)
	right_view.setup(1, board, exploration_manager, fog_manager, players)
	hud.setup(players, score_manager, difficulty)

	_connect_signals()
	p1_input.set_enabled(true)
	p2_input.set_enabled(true)

	remaining_time = float(difficulty.duration_seconds)
	hud.set_timer(remaining_time)
	hud.set_match_status("LIVE", UITheme.SUCCESS)
	hud.announce(0, "SECTOR LIVE // FIND THE MINES", UITheme.ACCENT, 2.6)
	hud.announce(1, "SECTOR LIVE // FIND THE MINES", UITheme.ACCENT, 2.6)
	_refresh_views()
	hud.refresh_players()

func _connect_signals() -> void:
	p1_input.move_step_requested.connect(_on_move_step_requested)
	p2_input.move_step_requested.connect(_on_move_step_requested)
	p1_input.reveal_pressed.connect(_on_reveal_pressed)
	p2_input.reveal_pressed.connect(_on_reveal_pressed)
	p1_input.flag_pressed.connect(_on_flag_pressed)
	p2_input.flag_pressed.connect(_on_flag_pressed)
	p1_input.facing_changed.connect(_on_facing_changed)
	p2_input.facing_changed.connect(_on_facing_changed)

	exploration_manager.player_memory_changed.connect(_on_player_memory_changed)
	fog_manager.vision_changed.connect(_on_vision_changed)
	flag_manager.flag_changed.connect(_on_flag_changed)
	flag_manager.action_rejected.connect(_on_action_rejected)
	health_manager.player_damaged.connect(_on_player_damaged)
	health_manager.player_protected.connect(_on_player_protected)
	health_manager.player_eliminated.connect(_on_player_eliminated)
	respawn_manager.respawn_countdown_changed.connect(_on_respawn_countdown)
	respawn_manager.player_respawned.connect(_on_player_respawned)

	hud.pause_resume_requested.connect(_on_resume_requested)
	hud.pause_restart_requested.connect(_on_restart_requested)
	hud.pause_menu_requested.connect(_on_main_menu_requested)
	hud.quit_requested.connect(_on_quit_requested)
	hud.rematch_requested.connect(_on_restart_requested)
	hud.result_menu_requested.connect(_on_main_menu_requested)

func _physics_process(_delta: float) -> void:
	if state != MatchState.PLAYING or get_tree().paused:
		return

	var moves := _pending_moves
	_pending_moves = {}
	if not moves.is_empty():
		apply_move_requests(moves)

	var actions := _pending_actions
	_pending_actions = []
	for action in actions:
		match action.get("type", &""):
			&"reveal":
				perform_reveal(action["player_id"])
			&"flag":
				perform_flag(action["player_id"])

func _process(delta: float) -> void:
	if state != MatchState.PLAYING or get_tree().paused:
		return
	remaining_time = maxf(0.0, remaining_time - delta)
	hud.set_timer(remaining_time)
	if remaining_time <= 0.0:
		finish_match()

func apply_move_requests(requests: Dictionary) -> Dictionary:
	if state != MatchState.PLAYING:
		return {}
	var accepted := GridMovement.resolve(requests, players, grid_manager.board)
	var moved := false
	for player_id in accepted.keys():
		var player: PlayerState = players[player_id]
		player.cell = accepted[player_id]
		moved = true
		fog_manager.recompute(player_id, player.cell)

		var index := grid_manager.index_of(player.cell)
		if grid_manager.is_bomb(index):
			exploration_manager.mark_bomb_seen(player_id, index)
			_play_explosion_in_views(index)
			audio_manager.play(&"explosion", 1.0, 0.94 + 0.04 * player_id)
			health_manager.apply_damage(player_id, HealthManager.DamageCause.STEP_ON_BOMB)

	if moved:
		_refresh_views()
		hud.refresh_players()
	return accepted

func perform_reveal(player_id: int) -> Dictionary:
	if state != MatchState.PLAYING:
		return {"ok": false, "reason": &"match_ended"}
	var player: PlayerState = players[player_id]
	if not player.is_active_for_actions():
		return {"ok": false, "reason": &"cannot_act"}

	var target := player.target_cell()
	if not grid_manager.in_bounds(target):
		_announce_rejection(player_id, "NO TILE IN FRONT")
		return {"ok": false, "reason": &"out_of_bounds"}

	var index := grid_manager.index_of(target)
	if grid_manager.has_flag(index):
		if grid_manager.flag_owner(index) == player_id:
			_announce_rejection(player_id, "REMOVE YOUR FLAG FIRST")
		else:
			_announce_rejection(player_id, "ENEMY FLAG BLOCKS THE TILE")
		return {"ok": false, "reason": &"flag_blocked"}

	if grid_manager.is_bomb(index):
		exploration_manager.mark_bomb_seen(player_id, index)
		_play_explosion_in_views(index)
		audio_manager.play(&"explosion", 2.0, 0.96 + 0.03 * player_id)
		health_manager.apply_damage(player_id, HealthManager.DamageCause.REVEAL_BOMB)
		_refresh_views()
		hud.refresh_players()
		return {"ok": true, "bomb": true, "index": index}

	var newly_revealed := exploration_manager.mark_safe_revealed(player_id, index)
	if newly_revealed:
		audio_manager.play(&"reveal", -2.0, 1.0 + 0.05 * player_id)
	_refresh_views()
	hud.refresh_players()
	return {"ok": true, "bomb": false, "index": index, "new": newly_revealed}

func perform_flag(player_id: int) -> bool:
	if state != MatchState.PLAYING:
		return false
	var player: PlayerState = players[player_id]
	if not player.is_active_for_actions():
		return false
	var target := player.target_cell()
	if not grid_manager.in_bounds(target):
		_announce_rejection(player_id, "NO TILE IN FRONT")
		return false
	return flag_manager.toggle_flag(player_id, grid_manager.index_of(target))

func finish_match() -> void:
	if state != MatchState.PLAYING:
		return
	state = MatchState.ENDED
	remaining_time = 0.0
	_pending_moves.clear()
	_pending_actions.clear()
	respawn_manager.enabled = false
	p1_input.set_enabled(false)
	p2_input.set_enabled(false)
	hud.set_timer(0.0)
	hud.set_match_status("FINAL", UITheme.CYAN)

	var scores := score_manager.both_scores()
	var winner_id := score_manager.winner_id()
	var stats: Array[Dictionary] = []
	for player in players:
		stats.append({
			"bombs": player.bombs_triggered,
			"eliminations": player.eliminations,
		})

	hud.refresh_players()
	audio_manager.play(&"victory", 1.0)
	hud.show_result({
		"winner_id": winner_id,
		"scores": scores,
		"difficulty": difficulty,
		"stats": stats,
	})

func _on_move_step_requested(player_id: int, direction: Vector2i) -> void:
	if state != MatchState.PLAYING:
		return
	if not players[player_id].is_active_for_actions():
		return
	_pending_moves[player_id] = direction

func _on_reveal_pressed(player_id: int) -> void:
	if state != MatchState.PLAYING:
		return
	_pending_actions.append({"player_id": player_id, "type": &"reveal"})

func _on_flag_pressed(player_id: int) -> void:
	if state != MatchState.PLAYING:
		return
	_pending_actions.append({"player_id": player_id, "type": &"flag"})

func _on_facing_changed(player_id: int, direction: Vector2i) -> void:
	if state != MatchState.PLAYING:
		return
	players[player_id].facing = direction
	_view_for(player_id).refresh()
	hud.refresh_players()

func _on_player_memory_changed(player_id: int) -> void:
	_view_for(player_id).refresh()

func _on_vision_changed(player_id: int) -> void:
	_view_for(player_id).refresh()

func _on_flag_changed(index: int, owner_id: int, placed: bool) -> void:
	_refresh_views()
	hud.refresh_players()
	if index >= 0:
		audio_manager.play(&"flag", 0.0, 1.0 if placed else 0.88)
		if placed:
			_view_for(owner_id).trigger_damage_shake(2.0)

func _on_action_rejected(player_id: int, reason: StringName) -> void:
	var messages := {
		&"cannot_act": "CANNOT ACT RIGHT NOW",
		&"out_of_bounds": "NO TILE IN FRONT",
		&"enemy_flag": "ENEMY FLAG BLOCKS THE TILE",
		&"already_revealed": "TILE ALREADY REVEALED",
		&"no_flags": "NO FLAGS LEFT",
		&"tile_occupied": "TILE OCCUPIED",
	}
	_announce_rejection(player_id, messages.get(reason, "ACTION BLOCKED"))

func _on_player_damaged(player_id: int, lives_remaining: int, cause: HealthManager.DamageCause) -> void:
	audio_manager.play(&"damage", 2.0, 0.92 + 0.05 * player_id)
	_view_for(player_id).trigger_damage_shake(8.0)
	hud.flash_player(player_id)
	var cause_text := "MINE REVEALED" if cause == HealthManager.DamageCause.REVEAL_BOMB else "MINE TRIGGERED"
	hud.announce(
		player_id,
		"%s // %d %s LEFT" % [cause_text, lives_remaining, "LIFE" if lives_remaining == 1 else "LIVES"],
		UITheme.DANGER,
		2.4
	)
	hud.refresh_players()
	_refresh_views()

func _on_player_protected(player_id: int, _cause: HealthManager.DamageCause) -> void:
	audio_manager.play(&"protected", 0.0)
	hud.flash_player(player_id, UITheme.CYAN, 0.18)
	hud.announce(player_id, "SHIELD ABSORBED THE BLAST", UITheme.CYAN, 2.2)
	hud.refresh_players()
	_refresh_views()

func _on_player_eliminated(player_id: int) -> void:
	flag_manager.remove_all_owned(player_id)
	players[player_id].flags_available = 0
	exploration_manager.clear_all_bomb_seen(player_id)
	respawn_manager.schedule(player_id)
	_controller_for(player_id).set_enabled(false)
	hud.flash_player(player_id, UITheme.DANGER, 0.4)
	hud.announce(player_id, "OPERATOR DOWN // RESPAWNING", UITheme.DANGER, 2.6)
	hud.refresh_players()
	_refresh_views()

func _on_respawn_countdown(player_id: int, seconds_left: int) -> void:
	players[player_id].respawn_time_left = float(seconds_left)
	hud.set_respawn_seconds(player_id, seconds_left)
	hud.refresh_players()

func _on_player_respawned(player_id: int, _cell: Vector2i) -> void:
	_controller_for(player_id).set_enabled(true)
	_view_for(player_id).snap_camera()
	audio_manager.play(&"respawn", 0.0)
	hud.announce(player_id, "BACK ONLINE // SHIELD READY", UITheme.CYAN, 2.4)
	hud.refresh_players()
	_refresh_views()

func _announce_rejection(player_id: int, message: String) -> void:
	audio_manager.play(&"denied", -3.0)
	hud.announce(player_id, message, UITheme.DANGER, 1.6)

func _play_explosion_in_views(index: int) -> void:
	var cell := grid_manager.cell_of(index)
	if fog_manager.is_visible(0, index):
		left_view.play_explosion(cell, index)
	if fog_manager.is_visible(1, index):
		right_view.play_explosion(cell, index)

func _view_for(player_id: int) -> ArenaView:
	return left_view if player_id == 0 else right_view

func _controller_for(player_id: int) -> PlayerController:
	return p1_input if player_id == 0 else p2_input

func _refresh_views() -> void:
	left_view.refresh()
	right_view.refresh()

func _set_paused(paused: bool) -> void:
	if state != MatchState.PLAYING:
		return
	if paused:
		_pending_moves.clear()
		_pending_actions.clear()
		get_tree().paused = true
		hud.show_pause(true)
	else:
		get_tree().paused = false
		hud.show_pause(false)
		get_viewport().gui_release_focus()

func _input(event: InputEvent) -> void:
	if state != MatchState.PLAYING:
		return
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()

func _on_resume_requested() -> void:
	_set_paused(false)

func _on_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _on_quit_requested() -> void:
	get_tree().paused = false
	get_tree().quit()
