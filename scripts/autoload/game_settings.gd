extends Node

var selected_difficulty: StringName = &"medium"

func get_difficulty() -> DifficultyConfig:
	return DifficultyConfig.get_profile(selected_difficulty)
