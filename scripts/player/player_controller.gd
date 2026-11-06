class_name PlayerController
extends Node

signal move_step_requested(player_id: int, direction: Vector2i)
signal reveal_pressed(player_id: int)
signal flag_pressed(player_id: int)
signal facing_changed(player_id: int, direction: Vector2i)

@export var player_id: int = 0

var enabled := true

var _action_to_direction := {}
var _held_actions: Array[StringName] = []
var _current_direction := Vector2i.ZERO
var _hold_elapsed := 0.0
var _step_accumulator := 0.0
var _has_started_moving := false

func _ready() -> void:
	var prefix := "p%d_" % (player_id + 1)
	_action_to_direction = {
		StringName(prefix + "up"): Vector2i.UP,
		StringName(prefix + "down"): Vector2i.DOWN,
		StringName(prefix + "left"): Vector2i.LEFT,
		StringName(prefix + "right"): Vector2i.RIGHT,
	}

func set_enabled(value: bool) -> void:
	enabled = value
	_reset_movement_state()
	_held_actions.clear()

func _physics_process(delta: float) -> void:
	if not enabled:
		return

	_update_held_directions()
	var next_direction := Vector2i.ZERO
	if not _held_actions.is_empty():
		next_direction = _action_to_direction[_held_actions.back()]

	if next_direction != _current_direction:
		_current_direction = next_direction
		_hold_elapsed = 0.0
		_step_accumulator = 0.0
		_has_started_moving = false
		if _current_direction != Vector2i.ZERO:
			facing_changed.emit(player_id, _current_direction)

	if _current_direction != Vector2i.ZERO:
		_hold_elapsed += delta
		if _hold_elapsed >= GameConfig.HOLD_TO_MOVE_SECONDS:
			if not _has_started_moving:
				_has_started_moving = true
				_step_accumulator = 0.0
				move_step_requested.emit(player_id, _current_direction)
			else:
				_step_accumulator += delta
				while _step_accumulator >= GameConfig.MOVE_STEP_SECONDS:
					_step_accumulator -= GameConfig.MOVE_STEP_SECONDS
					move_step_requested.emit(player_id, _current_direction)

	if Input.is_action_just_pressed(_action_name("reveal")):
		reveal_pressed.emit(player_id)
	if Input.is_action_just_pressed(_action_name("flag")):
		flag_pressed.emit(player_id)

func _update_held_directions() -> void:
	for action in _action_to_direction.keys():
		if Input.is_action_just_pressed(action):
			_held_actions.erase(action)
			_held_actions.append(action)
		elif Input.is_action_just_released(action):
			_held_actions.erase(action)

	for action in _held_actions.duplicate():
		if not Input.is_action_pressed(action):
			_held_actions.erase(action)

func _reset_movement_state() -> void:
	_current_direction = Vector2i.ZERO
	_hold_elapsed = 0.0
	_step_accumulator = 0.0
	_has_started_moving = false

func _action_name(suffix: String) -> StringName:
	return StringName("p%d_%s" % [player_id + 1, suffix])
