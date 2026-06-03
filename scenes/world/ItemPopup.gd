extends Label

# Floats upward and fades out when an item is mined

const FLOAT_SPEED := 40.0
const LIFETIME    := 1.2

var _timer: float = 0.0

func _ready() -> void:
	# Style
	add_theme_font_size_override("font_size", 14)
	add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)

func setup(item_id: String, world_pos: Vector2) -> void:
	text = "+ " + item_id.replace("_", " ").capitalize()
	global_position = world_pos + Vector2(-20, -20)
	_timer = 0.0

func _process(delta: float) -> void:
	_timer += delta
	position.y -= FLOAT_SPEED * delta
	modulate.a = 1.0 - (_timer / LIFETIME)
	if _timer >= LIFETIME:
		queue_free()
