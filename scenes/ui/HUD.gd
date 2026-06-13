extends CanvasLayer

@onready var joystick:        Control     = $VirtualJoystick
@onready var mode_overlay:    ColorRect   = $ModeOverlay
@onready var mat_label:       Label       = $ResourceBar/MatLabel
@onready var ammo_label:      Label       = $ResourceBar/AmmoLabel
@onready var mode_btn:        Button      = $ModeButton
@onready var rotate_btn:      Button      = $RotateButton
@onready var build_menu:      BuildMenu = $BuildMenu

var player: CharacterBody2D

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		joystick.direction_changed.connect(_on_joystick_moved)

	Inventory.changed.connect(_on_inventory_changed)
	_on_inventory_changed()
	_refresh_mode_ui()

	mode_btn.pressed.connect(_on_mode_btn_pressed)
	rotate_btn.pressed.connect(_on_rotate_btn_pressed)
	build_menu.build_selected.connect(_on_build_selected)

# ── Joystick ───────────────────────────────────────────────────────────────────

func _on_joystick_moved(direction: Vector2) -> void:
	if player:
		player.move_direction = direction

# ── Inventory display ──────────────────────────────────────────────────────────

func _on_inventory_changed() -> void:
	mat_label.text  = "⚙ %d/%d" % [Inventory.building_materials, Inventory.MAX_BUILDING_MATERIALS]
	ammo_label.text = "⬟ %d/%d" % [Inventory.ammo, Inventory.MAX_AMMO]

	# Warn low resources
	mat_label.modulate  = Color(1.0, 0.4, 0.3) if Inventory.building_materials < 5  else Color.WHITE
	ammo_label.modulate = Color(1.0, 0.4, 0.3) if Inventory.ammo < 10              else Color.WHITE

# ── Mode button ────────────────────────────────────────────────────────────────

func _on_mode_btn_pressed() -> void:
	if not player:
		return
	var new_mode: int = 1 - player.get_mode()
	player.set_mode(new_mode)
	_refresh_mode_ui()

func _refresh_mode_ui() -> void:
	if not player:
		return
	var m: int = player.get_mode()
	if m == 0:
		mode_btn.text       = "⚙ BUILD"
		mode_overlay.color  = Color(0.20, 0.50, 0.90, 0.06)
		rotate_btn.visible  = true
		build_menu.visible  = true
	else:
		mode_btn.text       = "⊕ SHOOT"
		mode_overlay.color  = Color(0.90, 0.25, 0.20, 0.06)
		rotate_btn.visible  = false
		build_menu.visible  = false

# ── Build rotation ─────────────────────────────────────────────────────────────

func _on_rotate_btn_pressed() -> void:
	if player:
		player.rotate_build_dir()

# ── Build menu (building selection) ───────────────────────────────────────────

func _on_build_selected(type: String) -> void:
	if player:
		player.set_build_type(type)
