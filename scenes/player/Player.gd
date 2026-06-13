extends CharacterBody2D

const SPEED_NORMAL  := 280.0
const SPEED_SHOOT   := 170.0   # slower while shooting
const MINING_RANGE  := 90.0

# MODE: 0 = build, 1 = shoot
var _mode: int = 0

var move_direction: Vector2 = Vector2.ZERO   # from virtual joystick
var _aim_angle:    float    = 0.0
var _facing_angle: float    = 0.0

# Shooting
var _shoot_cooldown:  float = 0.0
const SHOOT_RATE:     float = 0.18  # seconds between shots
var _is_shooting:     bool  = false
var _shoot_target:    Vector2 = Vector2.ZERO
var _muzzle_flash:    float = 0.0
const MUZZLE_DURATION: float = 0.06

# Build
var _selected_building: String = "conveyor"
var _selected_dir:      int    = 1  # East default
var _ghost_cell:        Vector2i = Vector2i(-9999, -9999)

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	var kb: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir: Vector2 = (move_direction + kb)
	if dir.length() > 1.0:
		dir = dir.normalized()

	var speed: float = SPEED_SHOOT if (_mode == 1 and _is_shooting) else SPEED_NORMAL
	velocity = dir * speed
	move_and_slide()

	# Facing direction (movement-based, overridden by aim in shoot mode)
	if dir.length() > 0.15:
		_facing_angle = dir.angle() + PI * 0.5

	if _mode == 1 and _is_shooting:
		_facing_angle = _aim_angle + PI * 0.5

	# Auto-cancel mining when out of range
	if MiningSystem.is_mining:
		if global_position.distance_to(MiningSystem.target_world_pos) > MINING_RANGE:
			MiningSystem.stop_mining()

	# Shoot tick
	if _mode == 1 and _is_shooting:
		_shoot_cooldown -= delta
		if _shoot_cooldown <= 0.0:
			_shoot_cooldown = SHOOT_RATE
			_fire()

	# Muzzle flash decay
	if _muzzle_flash > 0.0:
		_muzzle_flash -= delta / MUZZLE_DURATION
		_muzzle_flash = maxf(_muzzle_flash, 0.0)
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var is_touch:    bool = event is InputEventScreenTouch
	var is_mouse:    bool = event is InputEventMouseButton
	var is_drag:     bool = event is InputEventScreenDrag
	var is_mouse_mv: bool = event is InputEventMouseMotion

	var screen_pos: Vector2 = Vector2.ZERO
	var pressed:    bool    = false
	var released:   bool    = false

	if is_touch:
		screen_pos = event.position
		pressed    = event.pressed
		released   = not event.pressed
	elif is_mouse:
		screen_pos = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			pressed  = event.pressed
			released = not event.pressed
	elif is_drag:
		screen_pos = event.position
	elif is_mouse_mv:
		screen_pos = event.position

	# Left half = joystick zone, handled by VirtualJoystick
	var vw: float = get_viewport_rect().size.x
	if screen_pos.x < vw * 0.45:
		return

	var world_pos: Vector2 = _screen_to_world(screen_pos)

	match _mode:
		0:  # BUILD mode
			if pressed:
				_on_build_tap(world_pos)
			elif is_drag or is_mouse_mv:
				_update_ghost(world_pos)

		1:  # SHOOT mode
			if pressed:
				_is_shooting  = true
				_shoot_target = world_pos
				_aim_angle    = (world_pos - global_position).angle()
				_shoot_cooldown = 0.0  # fire immediately
				queue_redraw()
			elif released:
				_is_shooting = false
				queue_redraw()
			elif is_drag or is_mouse_mv:
				if _is_shooting:
					_shoot_target = world_pos
					_aim_angle    = (world_pos - global_position).angle()
					queue_redraw()

# ── Build mode ─────────────────────────────────────────────────────────────────

func _on_build_tap(world_pos: Vector2) -> void:
	var tap_cell: Vector2i = BuildingManager.world_to_cell(world_pos)

	# Tap existing building → open its UI or remove it
	if BuildingManager.has_building(tap_cell):
		var b: Node2D = BuildingManager.get_building(tap_cell)
		if b.has_signal("opened"):
			b.emit_signal("opened", b)
		return

	# Otherwise place selected building
	BuildingManager.place_building(tap_cell, _selected_building, _selected_dir)

func _update_ghost(world_pos: Vector2) -> void:
	_ghost_cell = BuildingManager.world_to_cell(world_pos)
	queue_redraw()

func set_build_type(type: String) -> void:
	_selected_building = type
	queue_redraw()

func set_build_direction(dir: int) -> void:
	_selected_dir = dir
	queue_redraw()

func rotate_build_dir() -> void:
	_selected_dir = (_selected_dir + 1) % 4
	queue_redraw()

# ── Mode switching ─────────────────────────────────────────────────────────────

func set_mode(m: int) -> void:
	_mode        = m
	_is_shooting = false
	_ghost_cell  = Vector2i(-9999, -9999)
	MiningSystem.stop_mining()
	queue_redraw()

func get_mode() -> int:
	return _mode

# ── Shooting ───────────────────────────────────────────────────────────────────

func _fire() -> void:
	if not Inventory.use_ammo(1):
		_is_shooting = false
		return

	var gun_tip: Vector2 = global_position + Vector2(0, -18).rotated(_aim_angle)

	var bullet := Node2D.new()
	var scr: Script = load("res://scenes/world/Bullet.gd")
	if scr:
		bullet.set_script(scr)
	get_parent().add_child(bullet)
	if bullet.has_method("launch"):
		bullet.launch(gun_tip, _shoot_target)

	_muzzle_flash = 1.0
	_screen_shake(4.0, 0.12)
	queue_redraw()

func _screen_shake(amount: float, duration: float) -> void:
	var tween: Tween = create_tween()
	var steps: int   = 6
	for i in steps:
		var off := Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		tween.tween_property(camera, "offset", off, duration / steps)
	tween.tween_property(camera, "offset", Vector2.ZERO, duration / steps)

# ── Drawing ────────────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_character()
	if _mode == 0:
		_draw_build_ghost()

func _draw_character() -> void:
	var body_color:   Color = Color(0.12, 0.16, 0.24)
	var accent_color: Color = Color(0.25, 0.82, 0.92) if _mode == 0 else Color(0.95, 0.35, 0.25)
	var core_color:   Color = accent_color.lightened(0.2)

	# Rotate everything around player forward direction
	var pts: PackedVector2Array = PackedVector2Array()
	var body_verts := [
		Vector2(0, -12),    # nose (forward)
		Vector2(7, -5),
		Vector2(10, 4),
		Vector2(5, 10),
		Vector2(-5, 10),
		Vector2(-10, 4),
		Vector2(-7, -5),
	]
	for v in body_verts:
		pts.append(v.rotated(_facing_angle))
	draw_colored_polygon(pts, body_color)

	# Body highlight
	var hi_pts := PackedVector2Array([
		Vector2(0, -10).rotated(_facing_angle),
		Vector2(5, -4).rotated(_facing_angle),
		Vector2(-5, -4).rotated(_facing_angle),
	])
	draw_colored_polygon(hi_pts, body_color.lightened(0.25))

	# Core circle
	draw_circle(Vector2.ZERO, 4.0, core_color)
	draw_circle(Vector2.ZERO, 2.5, Color(1, 1, 1, 0.6))

	# Gun barrel
	var barrel_start := Vector2(0, -10).rotated(_facing_angle)
	var barrel_end   := Vector2(0, -20).rotated(_facing_angle)
	draw_line(barrel_start, barrel_end, accent_color, 3.0, true)

	# Muzzle flash
	if _muzzle_flash > 0.0:
		var tip: Vector2 = Vector2(0, -22).rotated(_facing_angle)
		var a:   float   = _muzzle_flash
		draw_circle(tip, 10.0 * a, Color(1.0, 0.9, 0.4, a * 0.7))
		draw_circle(tip, 5.0 * a,  Color(1.0, 1.0, 0.8, a))

func _draw_build_ghost() -> void:
	if _ghost_cell == Vector2i(-9999, -9999):
		return
	# Convert ghost cell to local space
	var world_pos: Vector2 = BuildingManager.cell_to_world(_ghost_cell)
	var local_pos: Vector2 = to_local(world_pos)
	var can: bool = BuildingManager.can_place(_ghost_cell, _selected_building)
	var col: Color = Color(0.3, 0.9, 0.4, 0.4) if can else Color(0.9, 0.2, 0.2, 0.4)
	draw_rect(Rect2(local_pos - Vector2(16, 16), Vector2(32, 32)), col)

# ── Helpers ────────────────────────────────────────────────────────────────────

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func take_damage(amount: int) -> void:
	var hc: Node = get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(amount)
