class_name ExplosionEffect
extends Node2D

var _elapsed := 0.0
var _duration := 0.62
var _variant := 0

func setup(cell: Vector2i, variant: int = 0) -> void:
	position = Vector2(cell) * GameConfig.TILE_SIZE + Vector2.ONE * (GameConfig.TILE_SIZE * 0.5)
	_variant = variant
	z_index = 40

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= _duration:
		queue_free()

func _draw() -> void:
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	var fade := 1.0 - t
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var radius := lerpf(8.0, 54.0, eased)
	var core_color := Color(1.0, 0.78, 0.33, fade * 0.95)
	var ring_color := Color(1.0, 0.29, 0.16, fade * 0.8)
	var smoke_color := Color(0.09, 0.08, 0.07, fade * 0.5)

	draw_circle(Vector2.ZERO, lerpf(4.0, 20.0, eased), smoke_color)
	draw_circle(Vector2.ZERO, lerpf(4.0, 15.0, eased), core_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, ring_color, maxf(1.0, 4.0 * fade))
	draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 32, Color(1.0, 0.55, 0.2, fade * 0.7), 2.0)

	for spark_index in 10:
		var angle := TAU * float(spark_index) / 10.0 + float(_variant % 7) * 0.37
		var spread := lerpf(8.0, 42.0 + (spark_index % 3) * 9.0, eased)
		var start_point := Vector2(cos(angle), sin(angle)) * (spread * 0.45)
		var end_point := Vector2(cos(angle), sin(angle)) * spread
		var spark_color := Color(1.0, 0.72, 0.32, fade)
		draw_line(start_point, end_point, spark_color, maxf(1.0, 2.5 * fade))

	var inner_glow := Color(1.0, 0.42, 0.12, fade * 0.22)
	draw_circle(Vector2.ZERO, radius * 0.8, inner_glow)
