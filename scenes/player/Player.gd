extends CharacterBody2D

const SPEED         := 300.0
const MINING_RANGE  := 80.0  # pixels — about 2.5 tiles

var move_direction: Vector2 = Vector2.ZERO

@onready var sprite:           Sprite2D = $Sprite2D
@onready var health_component: Node     = $HealthComponent

func _ready() -> void:
	sprite.texture = _build_sprite()

func _physics_process(_delta: float) -> void:
	var kb  := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := (move_direction + kb).normalized() if (move_direction + kb).length() > 0 else Vector2.ZERO
	velocity = dir * SPEED
	move_and_slide()

	if dir != Vector2.ZERO:
		sprite.flip_h = dir.x < 0
		# Cancel mining if player walks out of range
		if MiningSystem.is_mining:
			var target_world := MiningSystem.target_world_pos
			if global_position.distance_to(target_world) > MINING_RANGE:
				MiningSystem.stop_mining()

func _unhandled_input(event: InputEvent) -> void:
	# Accept both touch taps (mobile) and left mouse click (PC)
	var pressed := false
	var screen_pos := Vector2.ZERO

	if event is InputEventScreenTouch and event.pressed:
		pressed     = true
		screen_pos  = event.position
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		pressed     = true
		screen_pos  = event.position

	if not pressed:
		return

	# Joystick owns the left half — ignore taps there
	if screen_pos.x < get_viewport_rect().size.x * 0.45:
		return

	var world_pos := _screen_to_world(screen_pos)
	var dist      := global_position.distance_to(world_pos)

	if dist > MINING_RANGE:
		return  # Too far away

	MiningSystem.try_mine(world_pos)

# ── Helpers ───────────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

# ── Procedural player sprite (placeholder until art is ready) ─────────────────
func _build_sprite() -> ImageTexture:
	const W := 24
	const H := 32
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	# Body — dark blue jacket
	var body := Color(0.18, 0.35, 0.72)
	var shadow := body.darkened(0.25)
	for x in range(3, 21):
		for y in range(14, 30):
			var shade := shadow if x < 6 or x > 18 else body
			img.set_pixel(x, y, shade)

	# Legs — darker
	var legs := Color(0.12, 0.18, 0.35)
	for x in range(4, 10):
		for y in range(24, 32):
			img.set_pixel(x, y, legs)
	for x in range(14, 20):
		for y in range(24, 32):
			img.set_pixel(x, y, legs)

	# Head — skin tone, circular-ish
	var skin := Color(0.88, 0.72, 0.58)
	var cx   := W / 2.0
	var cy   := 8.0
	var rad  := 7.0
	for x in range(W):
		for y in range(H):
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy)) < rad:
				img.set_pixel(x, y, skin)

	# Hair — dark stripe across top of head
	var hair := Color(0.18, 0.12, 0.08)
	for x in range(5, 19):
		for y in range(2, 6):
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy)) < rad:
				img.set_pixel(x, y, hair)

	# Eyes — two dark pixels
	img.set_pixel(8,  9, Color(0.1, 0.1, 0.15))
	img.set_pixel(15, 9, Color(0.1, 0.1, 0.15))

	return ImageTexture.create_from_image(img)
