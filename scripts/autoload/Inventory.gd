extends Node

# Player carries only building materials and ammo — no raw resource inventory.
# Raw resources move through the automation pipeline (belts → machines → hub).

signal changed

var building_materials: int = 20   # start with enough for a couple machines
var ammo:               int = 60
const MAX_BUILDING_MATERIALS := 50
const MAX_AMMO               := 200

# Small raw-resource pouch for early manual mining (hidden from main UI)
var _backpack: Dictionary = {}
const BACKPACK_MAX_PER_ITEM := 20

# ── Building materials ─────────────────────────────────────────────────────────

func add_building_materials(amount: int) -> void:
	building_materials = mini(building_materials + amount, MAX_BUILDING_MATERIALS)
	changed.emit()

func use_building_materials(amount: int) -> bool:
	if building_materials < amount:
		return false
	building_materials -= amount
	changed.emit()
	return true

# ── Ammo ──────────────────────────────────────────────────────────────────────

func add_ammo(amount: int) -> void:
	ammo = mini(ammo + amount, MAX_AMMO)
	changed.emit()

func use_ammo(amount: int) -> bool:
	if ammo < amount:
		return false
	ammo -= amount
	changed.emit()
	return true

# ── Backpack (raw resources, early-game only) ─────────────────────────────────

func add_to_backpack(item_id: String, amount: int = 1) -> void:
	var current: int = _backpack.get(item_id, 0)
	_backpack[item_id] = mini(current + amount, BACKPACK_MAX_PER_ITEM)
	changed.emit()

func take_from_backpack(item_id: String, amount: int = 1) -> int:
	var current: int = _backpack.get(item_id, 0)
	var taken:   int = mini(amount, current)
	if taken > 0:
		_backpack[item_id] = current - taken
		if _backpack[item_id] == 0:
			_backpack.erase(item_id)
		changed.emit()
	return taken

func get_backpack_count(item_id: String) -> int:
	return _backpack.get(item_id, 0)

func get_backpack() -> Dictionary:
	return _backpack.duplicate()

# Legacy compatibility for SaveManager
func get_save_data() -> Dictionary:
	return {
		"building_materials": building_materials,
		"ammo": ammo,
	}

func load_save_data(data: Dictionary) -> void:
	building_materials = data.get("building_materials", 20)
	ammo               = data.get("ammo", 60)
	changed.emit()
