extends CanvasLayer

@onready var joystick: Control = $VirtualJoystick
@onready var health_bar: ProgressBar = $HealthBar

var player: CharacterBody2D

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		var health: HealthComponent = player.get_node("HealthComponent")
		health.health_changed.connect(_on_health_changed)
		joystick.direction_changed.connect(_on_joystick_moved)
		_on_health_changed(health.current_health, health.max_health)

func _on_joystick_moved(direction: Vector2) -> void:
	if player:
		player.move_direction = direction

func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
