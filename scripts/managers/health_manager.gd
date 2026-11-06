class_name HealthManager
extends Node

enum DamageCause {
	REVEAL_BOMB,
	STEP_ON_BOMB,
}

signal player_damaged(player_id: int, lives_remaining: int, cause: DamageCause)
signal player_protected(player_id: int, cause: DamageCause)
signal player_eliminated(player_id: int)

var _players: Array[PlayerState] = []

func setup(players: Array[PlayerState]) -> void:
	_players = players

func apply_damage(player_id: int, cause: DamageCause) -> bool:
	if player_id < 0 or player_id >= _players.size():
		return false

	var player: PlayerState = _players[player_id]
	if player.is_eliminated or player.lives <= 0:
		return false

	if cause == DamageCause.REVEAL_BOMB and player.respawn_protection > 0:
		player.respawn_protection -= 1
		player_protected.emit(player_id, cause)
		return false

	player.lives -= 1
	player.bombs_triggered += 1
	player_damaged.emit(player_id, player.lives, cause)

	if player.lives <= 0:
		player.lives = 0
		player.is_eliminated = true
		player.eliminations += 1
		player_eliminated.emit(player_id)
	return true
