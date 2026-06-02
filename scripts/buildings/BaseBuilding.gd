extends Node2D
class_name BaseBuilding

# All buildings connect to the simulation tick instead of _process
# so they only run at TICK_RATE frequency, not every frame

@export var building_id: String = ""
@export var display_name: String = ""

func _ready() -> void:
	GameManager.on_tick.connect(_on_tick)

func _on_tick(_tick: int) -> void:
	pass  # Override in subclasses

func dismantle() -> void:
	GameManager.on_tick.disconnect(_on_tick)
	queue_free()
