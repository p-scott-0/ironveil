extends Node2D

var velocity: Vector2 = Vector2.ZERO
var _life:    float   = 0.45

func launch(world_pos: Vector2, target_world: Vector2) -> void:
	global_position = world_pos
	var dir: Vector2 = (target_world - world_pos).normalized()
	velocity = dir * 900.0
	rotation = dir.angle()

func _process(delta: float) -> void:
	global_position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _draw() -> void:
	# Elongated bullet shape in local space (rotated by node rotation)
	draw_rect(Rect2(-9, -2, 18, 4), Color(0.95, 0.88, 0.20))
	draw_rect(Rect2(-7, -1, 14, 2), Color(1.0, 1.0, 0.85))

func _ready() -> void:
	queue_redraw()
