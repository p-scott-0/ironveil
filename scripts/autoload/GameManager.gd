extends Node

# Central simulation tick — all buildings/conveyors update here, not in _process
# Slower tick rate keeps CPU usage low on mobile
const TICK_RATE := 0.1  # 10 ticks per second

var tick_count: int = 0
var _tick_timer: float = 0.0

signal on_tick(tick: int)

func _process(delta: float) -> void:
	_tick_timer += delta
	if _tick_timer >= TICK_RATE:
		_tick_timer -= TICK_RATE
		tick_count += 1
		on_tick.emit(tick_count)
