extends Control

# Emits a normalized direction vector for the player to consume
signal direction_changed(direction: Vector2)

const DEAD_ZONE := 10.0
const RADIUS := 80.0

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob

var _touch_index: int = -1
var _base_pos: Vector2

func _ready() -> void:
	_base_pos = base.global_position + base.size / 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _is_in_joystick_area(event.position):
			_touch_index = event.index
			_base_pos = event.position
			base.global_position = _base_pos - base.size / 2.0
		elif not event.pressed and event.index == _touch_index:
			_release()

	elif event is InputEventScreenDrag and event.index == _touch_index:
		var offset: Vector2 = event.position - _base_pos
		var clamped := offset.limit_length(RADIUS)
		knob.position = clamped - knob.size / 2.0 + base.size / 2.0
		var direction := Vector2.ZERO if offset.length() < DEAD_ZONE else clamped / RADIUS
		direction_changed.emit(direction)

func _release() -> void:
	_touch_index = -1
	knob.position = base.size / 2.0 - knob.size / 2.0
	direction_changed.emit(Vector2.ZERO)

func _is_in_joystick_area(pos: Vector2) -> bool:
	return pos.x < get_viewport_rect().size.x / 2.0 and pos.y > get_viewport_rect().size.y * 0.5
