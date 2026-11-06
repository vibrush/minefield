class_name GameConfig
extends RefCounted

const PLAYER_COUNT := 2
const TILE_SIZE := 56.0
const CAMERA_ZOOM := 1.5
const VISION_RADIUS := 1
const MOVE_SPEED_TILES_PER_SECOND := 2.0
const MOVE_STEP_SECONDS := 0.5
const HOLD_TO_MOVE_SECONDS := 0.18
const STARTING_LIVES := 3
const RESPAWN_PROTECTION_REVEALS := 1
const RESPAWN_DISTANCE_RATIO := 0.5
const RESPAWN_DELAY_SECONDS := 3.0
const FLAG_OWNER_NONE := -1

const PLAYER_NAMES := ["PLAYER 1", "PLAYER 2"]
const PLAYER_COLORS := [
	Color("#ffb454"),
	Color("#6fe3ff"),
]
const PLAYER_DARK_COLORS := [
	Color("#7a4f1d"),
	Color("#245f73"),
]
