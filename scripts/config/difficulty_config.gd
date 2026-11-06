class_name DifficultyConfig
extends Resource

@export var id: StringName = &"easy"
@export var display_name: String = "EASY"
@export var columns: int = 10
@export var rows: int = 10
@export var bomb_count: int = 12
@export var duration_seconds: int = 180
@export_multiline var description: String = ""

const PROFILE_IDS: Array[StringName] = [&"easy", &"medium", &"hard"]

static func get_profile(profile_id: StringName) -> DifficultyConfig:
	match profile_id:
		&"easy":
			return _make(
				&"easy",
				"EASY",
				"Small sector. Light mine density. A short reconnaissance run.",
				10,
				10,
				12,
				180
			)
		&"hard":
			return _make(
				&"hard",
				"HARD",
				"Large open sector. Extreme mine density. Every tile is a gamble.",
				20,
				24,
				90,
				480
			)
		_:
			return _make(
				&"medium",
				"MEDIUM",
				"Standard operation. Dense enough to demand careful triangulation.",
				16,
				16,
				40,
				300
			)

static func get_all() -> Array[DifficultyConfig]:
	var profiles: Array[DifficultyConfig] = []
	for profile_id in PROFILE_IDS:
		profiles.append(get_profile(profile_id))
	return profiles

static func _make(
	profile_id: StringName,
	profile_name: String,
	profile_description: String,
	profile_columns: int,
	profile_rows: int,
	profile_bombs: int,
	profile_duration: int
) -> DifficultyConfig:
	var config := DifficultyConfig.new()
	config.id = profile_id
	config.display_name = profile_name
	config.columns = profile_columns
	config.rows = profile_rows
	config.bomb_count = profile_bombs
	config.duration_seconds = profile_duration
	config.description = profile_description
	return config

func tile_count() -> int:
	return columns * rows

func arena_text() -> String:
	return "%d × %d" % [columns, rows]

func flags_per_player() -> int:
	return bomb_count

func duration_text() -> String:
	var minutes := duration_seconds / 60
	var seconds := duration_seconds % 60
	return "%d:%02d" % [minutes, seconds]
