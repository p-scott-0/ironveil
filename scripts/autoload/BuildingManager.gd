extends Node

# ── Constants ──────────────────────────────────────────────────────────────────

const TILE_SIZE := 32

# Cardinal directions: N, E, S, W
const DIRS: Array = [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]

# Belt types encoded in _belt_dirs upper bits
const FLAG_BRIDGE   := 0x100
const FLAG_SPLITTER := 0x200

# Ticks before a belt item advances one cell
const BELT_TICKS := 2
# Ticks machines need per processing cycle (per-machine overrides exist)
const SMELTER_TICKS    := 6
const FABRICATOR_TICKS := 8
const ASSEMBLER_TICKS  := 10
const MINER_TICKS      := 5

signal building_placed(cell: Vector2i, type: String)
signal building_removed(cell: Vector2i)

# ── References (set by World.gd) ──────────────────────────────────────────────

var _belt_map:       TileMapLayer
var _machines_node:  Node2D
var _belt_items_node: Node2D
var _terrain_map:    TileMapLayer  # for reading tile types under miners

# ── State ──────────────────────────────────────────────────────────────────────

var _buildings:    Dictionary = {}  # Vector2i → machine Node2D
var _belt_dirs:    Dictionary = {}  # Vector2i → int (dir | flags)
var _belt_items:   Dictionary = {}  # Vector2i → item_id String
var _belt_item_nodes: Dictionary = {}  # Vector2i → Node2D visual

var _belt_source_ids:     Dictionary = {}  # dir (0-3) → source_id; 4=splitter, 5=bridge
var _belt_tick_counter:   int = 0
var _splitter_counters:   Dictionary = {}  # Vector2i → int (round-robin index)

# ── Setup ──────────────────────────────────────────────────────────────────────

func setup(belt_map: TileMapLayer, machines: Node2D, belt_items: Node2D, terrain: TileMapLayer) -> void:
	_belt_map        = belt_map
	_machines_node   = machines
	_belt_items_node = belt_items
	_terrain_map     = terrain
	_build_belt_tileset()
	GameManager.on_tick.connect(_on_global_tick)

# ── Belt tileset ───────────────────────────────────────────────────────────────

func _build_belt_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	for dir in 4:
		var src := TileSetAtlasSource.new()
		src.texture = _make_belt_tex(dir, false)
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		src.create_tile(Vector2i(0, 0))
		_belt_source_ids[dir] = ts.add_source(src)

	# Splitter (id 4)
	var sp := TileSetAtlasSource.new()
	sp.texture = _make_splitter_tex()
	sp.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	sp.create_tile(Vector2i(0, 0))
	_belt_source_ids[4] = ts.add_source(sp)

	# Bridge belt (id 5)
	var br := TileSetAtlasSource.new()
	br.texture = _make_belt_tex(1, true)  # default East; visually symmetric
	br.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	br.create_tile(Vector2i(0, 0))
	_belt_source_ids[5] = ts.add_source(br)

	_belt_map.tile_set = ts

func _make_belt_tex(dir: int, is_bridge: bool) -> ImageTexture:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # transparent

	var bg: Color
	var arrow: Color
	if is_bridge:
		bg    = Color(0.40, 0.55, 0.78, 0.55)
		arrow = Color(0.70, 0.85, 1.00, 0.80)
	else:
		bg    = Color(0.78, 0.78, 0.82, 1.0)
		arrow = Color(0.48, 0.48, 0.55, 1.0)

	# Belt body: rounded rect within tile
	_img_rounded_rect(img, 3, 3, 29, 29, 4, bg)

	# Direction arrows (two chevrons)
	for offset in [-5, 3]:
		_img_chevron(img, dir, offset, arrow)

	return ImageTexture.create_from_image(img)

func _make_splitter_tex() -> ImageTexture:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_img_rounded_rect(img, 3, 3, 29, 29, 4, Color(0.62, 0.80, 0.50, 1.0))
	# Y-branch visual: forward arrow + two side arrows
	_img_chevron(img, 1, -2, Color(0.28, 0.55, 0.22))  # right
	_img_chevron(img, 0, -2, Color(0.28, 0.55, 0.22))  # up
	_img_chevron(img, 2, -2, Color(0.28, 0.55, 0.22))  # down
	return ImageTexture.create_from_image(img)

func _img_rounded_rect(img: Image, x1: int, y1: int, x2: int, y2: int, r: int, color: Color) -> void:
	for px in range(x1, x2):
		for py in range(y1, y2):
			if px < 0 or px >= TILE_SIZE or py < 0 or py >= TILE_SIZE:
				continue
			var nx: int = clampi(px, x1 + r, x2 - r - 1)
			var ny: int = clampi(py, y1 + r, y2 - r - 1)
			var ddx: int = px - nx
			var ddy: int = py - ny
			if ddx * ddx + ddy * ddy <= r * r:
				img.set_pixel(px, py, color)

func _img_chevron(img: Image, dir: int, shift: int, color: Color) -> void:
	# Draw a small ">" shape pointing in direction dir, shifted along the belt axis
	var cx: int = 16
	var cy: int = 16
	match dir:
		1:  # East: > pointing right
			cx += shift
			for i in 5:
				var dy: int = i - 2
				var dx: int = abs(dy)
				_img_px(img, cx + dx, cy + dy, color)
				_img_px(img, cx + dx + 1, cy + dy, color)
		3:  # West: < pointing left
			cx -= shift
			for i in 5:
				var dy: int = i - 2
				var dx: int = abs(dy)
				_img_px(img, cx - dx, cy + dy, color)
				_img_px(img, cx - dx - 1, cy + dy, color)
		0:  # North: ^ pointing up
			cy += shift
			for i in 5:
				var dx: int = i - 2
				var dy: int = abs(dx)
				_img_px(img, cx + dx, cy - dy, color)
				_img_px(img, cx + dx, cy - dy - 1, color)
		2:  # South: v pointing down
			cy -= shift
			for i in 5:
				var dx: int = i - 2
				var dy: int = abs(dx)
				_img_px(img, cx + dx, cy + dy, color)
				_img_px(img, cx + dx, cy + dy + 1, color)

func _img_px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < TILE_SIZE and y >= 0 and y < TILE_SIZE:
		img.set_pixel(x, y, color)

# ── Placement API ──────────────────────────────────────────────────────────────

func can_place(cell: Vector2i, type: String) -> bool:
	if _buildings.has(cell):
		return false
	if type == "conveyor" or type == "bridge" or type == "splitter":
		return not _belt_dirs.has(cell)
	return not _buildings.has(cell) and not _belt_dirs.has(cell)

func place_building(cell: Vector2i, type: String, direction: int) -> bool:
	if not can_place(cell, type):
		return false
	var cost: int = RecipeBook.get_building_cost(type)
	if not Inventory.use_building_materials(cost):
		return false

	match type:
		"conveyor":
			_place_belt(cell, direction, 0)
		"bridge":
			_place_belt(cell, direction, FLAG_BRIDGE)
		"splitter":
			_place_belt(cell, direction, FLAG_SPLITTER)
		_:
			_place_machine(cell, type, direction)

	building_placed.emit(cell, type)
	return true

func _place_belt(cell: Vector2i, dir: int, flags: int) -> void:
	_belt_dirs[cell] = dir | flags
	var source_id: int
	if flags & FLAG_SPLITTER:
		source_id = _belt_source_ids[4]
	elif flags & FLAG_BRIDGE:
		source_id = _belt_source_ids[5]
	else:
		source_id = _belt_source_ids[dir]
	_belt_map.set_cell(cell, source_id, Vector2i(0, 0))

func _place_machine(cell: Vector2i, type: String, direction: int) -> void:
	var script_path: String = "res://scenes/buildings/" + _type_to_class(type) + ".gd"
	var scr: Script = load(script_path)
	if scr == null:
		push_error("BuildingManager: cannot load script " + script_path)
		return
	var node := Node2D.new()
	node.set_script(scr)
	node.position = cell_to_world(cell)
	_machines_node.add_child(node)
	if node.has_method("setup"):
		node.setup(cell, direction)
	_buildings[cell] = node

func _type_to_class(type: String) -> String:
	match type:
		"miner":      return "Miner"
		"smelter":    return "Smelter"
		"fabricator": return "Fabricator"
		"assembler":  return "Assembler"
		"hub":        return "Hub"
		_:            return type.capitalize()

func remove_building(cell: Vector2i) -> void:
	if _buildings.has(cell):
		_buildings[cell].queue_free()
		_buildings.erase(cell)
	if _belt_dirs.has(cell):
		_belt_dirs.erase(cell)
		_belt_map.erase_cell(cell)
	if _belt_items.has(cell):
		if _belt_item_nodes.has(cell):
			_belt_item_nodes[cell].queue_free()
			_belt_item_nodes.erase(cell)
		_belt_items.erase(cell)
	building_removed.emit(cell)

# ── Tick processing ────────────────────────────────────────────────────────────

func _on_global_tick(tick: int) -> void:
	# Tick all machines
	for cell in _buildings:
		var machine: Node2D = _buildings[cell]
		if machine.has_method("_machine_tick"):
			machine._machine_tick(tick)

	# Advance belt items every BELT_TICKS
	_belt_tick_counter += 1
	if _belt_tick_counter >= BELT_TICKS:
		_belt_tick_counter = 0
		_advance_belts()

func _advance_belts() -> void:
	# Collect cells with items, process downstream-first (sort by direction)
	var occupied: Array = _belt_items.keys()
	# Simple forward pass; good enough for linear belts
	for cell in occupied:
		if not _belt_items.has(cell):
			continue
		var item_id: String = _belt_items[cell]
		var flags:   int    = _belt_dirs.get(cell, -1)
		if flags < 0:
			continue
		var dir: int = flags & 0xFF

		if flags & FLAG_SPLITTER:
			_advance_splitter(cell, item_id)
		else:
			var next: Vector2i = cell + DIRS[dir]
			_try_advance(cell, next, item_id)

func _try_advance(from: Vector2i, to: Vector2i, item_id: String) -> bool:
	# Move to belt
	if _belt_dirs.has(to) and not _belt_items.has(to):
		_move_belt_item(from, to, item_id)
		return true
	# Deliver to machine
	if _buildings.has(to):
		var m: Node2D = _buildings[to]
		if m.has_method("try_accept_item") and m.try_accept_item(item_id):
			_remove_belt_item(from)
			return true
	return false

func _advance_splitter(cell: Vector2i, item_id: String) -> void:
	# Round-robin across up to 3 output directions (all except back)
	var flags: int = _belt_dirs[cell]
	var dir:   int = flags & 0xFF
	var back:  int = (dir + 2) % 4

	var outputs: Array = []
	for d in 4:
		if d != back:
			outputs.append(DIRS[d])

	var idx: int = _splitter_counters.get(cell, 0)
	for attempt in outputs.size():
		var out_dir: Vector2i = outputs[(idx + attempt) % outputs.size()]
		var to: Vector2i = cell + out_dir
		if _try_advance(cell, to, item_id):
			_splitter_counters[cell] = (idx + attempt + 1) % outputs.size()
			return

# ── Belt item management ───────────────────────────────────────────────────────

func inject_item(cell: Vector2i, item_id: String) -> bool:
	if _belt_items.has(cell):
		return false
	_belt_items[cell] = item_id
	_spawn_item_visual(cell, item_id)
	return true

func take_item_from_belt(cell: Vector2i) -> String:
	if not _belt_items.has(cell):
		return ""
	var item_id: String = _belt_items[cell]
	_remove_belt_item(cell)
	return item_id

func peek_belt_item(cell: Vector2i) -> String:
	return _belt_items.get(cell, "")

func _move_belt_item(from: Vector2i, to: Vector2i, item_id: String) -> void:
	_belt_items.erase(from)
	_belt_items[to] = item_id
	if _belt_item_nodes.has(from):
		var node: Node2D = _belt_item_nodes[from]
		_belt_item_nodes.erase(from)
		_belt_item_nodes[to] = node
		var tween: Tween = node.create_tween()
		tween.tween_property(node, "position", cell_to_world(to), 0.18)

func _remove_belt_item(cell: Vector2i) -> void:
	_belt_items.erase(cell)
	if _belt_item_nodes.has(cell):
		_belt_item_nodes[cell].queue_free()
		_belt_item_nodes.erase(cell)

func _spawn_item_visual(cell: Vector2i, item_id: String) -> void:
	var node := Node2D.new()
	var scr: Script = load("res://scenes/world/BeltItem.gd")
	if scr:
		node.set_script(scr)
	node.position = cell_to_world(cell)
	_belt_items_node.add_child(node)
	if node.has_method("setup"):
		node.setup(item_id)
	_belt_item_nodes[cell] = node

# ── Getters ────────────────────────────────────────────────────────────────────

func get_building(cell: Vector2i) -> Node2D:
	return _buildings.get(cell, null)

func has_building(cell: Vector2i) -> bool:
	return _buildings.has(cell)

func has_belt(cell: Vector2i) -> bool:
	return _belt_dirs.has(cell)

func get_terrain_type(cell: Vector2i) -> TileTypes.Type:
	if _terrain_map == null:
		return TileTypes.Type.GROUND
	var src: int = _terrain_map.get_cell_source_id(cell)
	if src < 0:
		return TileTypes.Type.GROUND
	return src as TileTypes.Type

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE + TILE_SIZE * 0.5,
	               cell.y * TILE_SIZE + TILE_SIZE * 0.5)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / TILE_SIZE)),
		int(floor(world_pos.y / TILE_SIZE))
	)

# Helper for machines: given a machine cell and its output direction, return the
# output cell and the two/three input cells (left, back, right relative to output)
func get_output_cell(cell: Vector2i, dir: int) -> Vector2i:
	return cell + DIRS[dir]

func get_input_cells(cell: Vector2i, dir: int, count: int) -> Array:
	var left:  Vector2i = cell + DIRS[(dir + 3) % 4]
	var back:  Vector2i = cell + DIRS[(dir + 2) % 4]
	var right: Vector2i = cell + DIRS[(dir + 1) % 4]
	match count:
		1: return [back]
		2: return [left, right]
		3: return [left, back, right]
	return []
