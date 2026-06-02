extends CharacterBody2D

const SPEED := 300.0

# Set by the virtual joystick UI on mobile, or read from keyboard on PC
var move_direction: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component: Node = $HealthComponent

func _physics_process(_delta: float) -> void:
	# Keyboard input blends with joystick so PC testing works without touch
	var kb := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := (move_direction + kb).normalized() if (move_direction + kb).length() > 0 else Vector2.ZERO
	velocity = dir * SPEED
	move_and_slide()
	if dir != Vector2.ZERO:
		sprite.flip_h = dir.x < 0

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)
