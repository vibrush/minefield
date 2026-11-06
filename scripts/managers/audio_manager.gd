class_name AudioManager
extends Node

const SOUND_FILES := {
	&"reveal": "res://assets/audio/reveal.wav",
	&"flag": "res://assets/audio/flag.wav",
	&"explosion": "res://assets/audio/explosion.wav",
	&"damage": "res://assets/audio/damage.wav",
	&"protected": "res://assets/audio/protected.wav",
	&"respawn": "res://assets/audio/respawn.wav",
	&"victory": "res://assets/audio/victory.wav",
	&"denied": "res://assets/audio/denied.wav",
	&"click": "res://assets/audio/click.wav",
}

var _players := {}

func _ready() -> void:
	for sound_name in SOUND_FILES.keys():
		var path: String = SOUND_FILES[sound_name]
		if not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = load(path)
		if stream == null:
			continue
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = -8.0
		player.bus = &"Master"
		add_child(player)
		_players[sound_name] = player

func play(sound_name: StringName, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not _players.has(sound_name):
		return
	var player: AudioStreamPlayer = _players[sound_name]
	player.volume_db = -8.0 + volume_db
	player.pitch_scale = pitch_scale
	player.play()

func play_ui_click() -> void:
	play(&"click", -6.0)
