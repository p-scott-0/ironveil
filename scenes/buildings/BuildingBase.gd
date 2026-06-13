extends Node2D
# Base class for all placed machines. Subclasses override _machine_tick() and _draw().

var cell:      Vector2i = Vector2i.ZERO
var direction: int      = 1  # 0=N, 1=E, 2=S, 3=W (output direction)

# Colour theme — override in subclass
var _bg_color:     Color = Color(0.18, 0.18, 0.22)
var _accent_color: Color = Color(0.80, 0.80, 0.80)

func setup(c: Vector2i, dir: int) -> void:
	cell      = c
	direction = dir
	queue_redraw()

func _machine_tick(_tick: int) -> void:
	pass  # override in subclass

func try_accept_item(_item_id: String) -> bool:
	return false  # override in subclass

func _draw() -> void:
	_draw_base()
	_draw_direction_arrow()

func _draw_base() -> void:
	# Rounded machine body
	var s: float = 14.0
	draw_rect(Rect2(-s, -s, s * 2, s * 2), _bg_color)
	# Inner highlight border
	draw_rect(Rect2(-s, -s, s * 2, s * 2), _accent_color.darkened(0.4), false, 1.5)

func _draw_direction_arrow() -> void:
	# Small triangle at the output side
	var angle: float = [PI * 1.5, 0.0, PI * 0.5, PI][direction]
	var tip  := Vector2(12.0, 0).rotated(angle)
	var bl   := Vector2(7.0, -3.5).rotated(angle)
	var br   := Vector2(7.0,  3.5).rotated(angle)
	draw_colored_polygon(PackedVector2Array([tip, bl, br]), _accent_color)
