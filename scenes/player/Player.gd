extends CharacterBody2D

const SPEED := 300.0

# Set by the virtual joystick UI on mobile, or read from keyboard on PC
var move_direction: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component: Node = $HealthComponent

func _physics_process(_delta: float) -> void:
	velocity = move_direction.normalized() * SPEED
	move_and_slide()
	if move_direction != Vector2.ZERO:
		sprite.flip_h = move_direction.x < 0

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)
