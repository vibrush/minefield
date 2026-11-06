class_name PlayerState
extends RefCounted

var id: int
var display_name: String
var color: Color
var dark_color: Color
var spawn_cell: Vector2i
var cell: Vector2i
var facing: Vector2i = Vector2i.RIGHT
var lives: int = GameConfig.STARTING_LIVES
var flags_available: int = 0
var flags_total: int = 0
var is_eliminated: bool = false
var respawn_time_left: float = 0.0
var respawn_protection: int = 0
var eliminations: int = 0
var bombs_triggered: int = 0

func _init(player_id: int) -> void:
	id = player_id
	display_name = GameConfig.PLAYER_NAMES[player_id]
	color = GameConfig.PLAYER_COLORS[player_id]
	dark_color = GameConfig.PLAYER_DARK_COLORS[player_id]

func configure_for_match(p_spawn_cell: Vector2i, p_facing: Vector2i, p_flags_total: int) -> void:
	spawn_cell = p_spawn_cell
	cell = p_spawn_cell
	facing = p_facing
	lives = GameConfig.STARTING_LIVES
	flags_total = p_flags_total
	flags_available = p_flags_total
	is_eliminated = false
	respawn_time_left = 0.0
	respawn_protection = 0
	eliminations = 0
	bombs_triggered = 0

func target_cell() -> Vector2i:
	return cell + facing

func facing_name() -> String:
	if facing == Vector2i.UP:
		return "N"
	if facing == Vector2i.DOWN:
		return "S"
	if facing == Vector2i.LEFT:
		return "W"
	return "E"

func coordinate_text() -> String:
	return "%d:%d" % [cell.x, cell.y]

func is_active_for_actions() -> bool:
	return not is_eliminated and lives > 0
