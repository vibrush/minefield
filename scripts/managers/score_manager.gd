class_name ScoreManager
extends Node

var _flag_manager: FlagManager
var _players: Array[PlayerState] = []

func setup(flag_manager: FlagManager, players: Array[PlayerState]) -> void:
	_flag_manager = flag_manager
	_players = players

func score_for(player_id: int) -> int:
	return _flag_manager.correct_count(player_id)

func both_scores() -> Array[int]:
	return [score_for(0), score_for(1)]

func winner_id() -> int:
	var scores := both_scores()
	if scores[0] > scores[1]:
		return 0
	if scores[1] > scores[0]:
		return 1
	return -1
