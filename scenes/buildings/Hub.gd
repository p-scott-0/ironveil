extends Node2D
# Accepts items from all 4 adjacent belts.
# building_material and ammo go straight to Inventory.
# Everything else is stored internally.

var cell:      Vector2i = Vector2i.ZERO
var direction: int      = 0  # unused, hubs accept all sides

const BG_COLOR     := Color(0.08, 0.18, 0.12)
const ACCENT_COLOR := Color(0.28, 0.90, 0.40)

var _store:    Dictionary = {}  # item_id → int
var _pulse:    float      = 0.0  # brief flash on receive

signal opened(hub_node: Node2D)

func setup(c: Vector2i, _dir: int) -> void:
	cell = c
	queue_redraw()

func _machine_tick(_tick: int) -> void:
	# Pull from all four adjacent belts
	for dir in 4:
		var adj: Vector2i = cell + BuildingManager.DIRS[dir]
		var item: String = BuildingManager.take_item_from_belt(adj)
		if item != "":
			_receive(item)

func _receive(item_id: String) -> void:
	match item_id:
		"building_material":
			Inventory.add_building_materials(1)
		"ammo":
			Inventory.add_ammo(1)
		_:
			_store[item_id] = _store.get(item_id, 0) + 1
	_pulse = 0.4
	queue_redraw()

func try_accept_item(item_id: String) -> bool:
	_receive(item_id)
	return true

func get_stored(item_id: String) -> int:
	return _store.get(item_id, 0)

func get_all_stored() -> Dictionary:
	return _store.duplicate()

func _process(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta, 0.0)
		queue_redraw()

func _draw() -> void:
	var s: float = 14.0
	var glow: Color = ACCENT_COLOR if _pulse <= 0.0 else Color(0.6, 1.0, 0.7, _pulse)

	draw_rect(Rect2(-s, -s, s * 2, s * 2), BG_COLOR)
	draw_rect(Rect2(-s, -s, s * 2, s * 2), glow.darkened(0.3), false, 2.0)

	# Diamond/hexagon hub icon
	var pts := PackedVector2Array([
		Vector2(0, -9), Vector2(7, -5), Vector2(7, 5),
		Vector2(0,  9), Vector2(-7, 5), Vector2(-7,-5),
	])
	draw_colored_polygon(pts, BG_COLOR.lightened(0.3))
	draw_polyline(PackedVector2Array([
		Vector2(0,-9), Vector2(7,-5), Vector2(7,5),
		Vector2(0,9), Vector2(-7,5), Vector2(-7,-5), Vector2(0,-9)
	]), glow, 1.5)

	# Centre diamond
	var inner := PackedVector2Array([
		Vector2(0,-4), Vector2(4,0), Vector2(0,4), Vector2(-4,0)
	])
	draw_colored_polygon(inner, glow)

	# Pulse ring
	if _pulse > 0.0:
		draw_circle(Vector2.ZERO, 14.0 + _pulse * 6.0, Color(glow.r, glow.g, glow.b, _pulse * 0.5))
