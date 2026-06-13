extends Node
class_name WorldGenerator

const WORLD_SIZE := 192
const TILE_SIZE  := 32
const HALF       := WORLD_SIZE / 2

# Noise thresholds at spawn distance
const STONE_THRESHOLD  := 0.55
const IRON_THRESHOLD   := 0.62
const COAL_THRESHOLD   := 0.60
const COPPER_THRESHOLD := 0.58

# Patch growth with distance
const SCALE_DISTANCE := 50.0
const SCALE_AMOUNT   := 0.30

@export var world_seed: int = 0

var _tile_map:   TileMapLayer
var _source_ids: Dictionary = {}  # TileTypes.Type -> source_id
var _tile_grid:  Array      = []  # [x][y] -> TileTypes.Type

signal generation_complete

func setup(tile_map: TileMapLayer) -> void:
	_tile_map = tile_map
	_build_tileset()
	_generate()
	generation_complete.emit()

# ── Tileset (Shapez aesthetic: light tiles, geometric resource shapes) ──────────

func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_physics_layer(0)

	for type in TileTypes.Type.values():
		var source := TileSetAtlasSource.new()
		source.texture = _make_tile_texture(type)
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		source.create_tile(Vector2i(0, 0))
		_source_ids[type] = ts.add_source(source)

	_tile_map.tile_set = ts

func _make_tile_texture(type: TileTypes.Type) -> ImageTexture:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)

	# Shapez-style: near-white background, coloured geometric shape for each resource
	img.fill(Color(0.93, 0.93, 0.95))

	match type:
		TileTypes.Type.GROUND:
			pass  # plain light tile
		TileTypes.Type.STONE:
			# Grey diamond (outer + inner highlight)
			_fill_diamond(img, 16, 16, 9, 9, Color(0.50, 0.50, 0.54))
			_fill_diamond(img, 16, 16, 5, 5, Color(0.68, 0.68, 0.72))
		TileTypes.Type.IRON:
			# Blue rounded square
			_fill_rounded_rect(img, 8, 8, 24, 24, 4, Color(0.22, 0.42, 0.85))
			_fill_rounded_rect(img, 11, 11, 21, 21, 3, Color(0.42, 0.62, 0.96))
		TileTypes.Type.COAL:
			# Near-black circle
			_fill_circle(img, 16, 16, 9, Color(0.14, 0.14, 0.17))
			_fill_circle(img, 14, 14, 4, Color(0.28, 0.28, 0.32))
		TileTypes.Type.COPPER:
			# Orange upward triangle (outer + inner highlight)
			_fill_triangle(img, 16, 6, 25, 23, 7, 23, Color(0.90, 0.48, 0.10))
			_fill_triangle(img, 16, 10, 22, 21, 10, 21, Color(0.98, 0.68, 0.30))

	_draw_border(img, Color(0.80, 0.80, 0.83))
	return ImageTexture.create_from_image(img)

# ── Pixel drawing helpers ──────────────────────────────────────────────────────

func _fill_circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(cx - r, cx + r + 1):
		for y in range(cy - r, cy + r + 1):
			if x < 0 or x >= TILE_SIZE or y < 0 or y >= TILE_SIZE:
				continue
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(x, y, color)

func _fill_rounded_rect(img: Image, x1: int, y1: int, x2: int, y2: int, r: int, color: Color) -> void:
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

func _fill_diamond(img: Image, cx: int, cy: int, hw: int, hh: int, color: Color) -> void:
	for x in range(cx - hw, cx + hw + 1):
		for y in range(cy - hh, cy + hh + 1):
			if x < 0 or x >= TILE_SIZE or y < 0 or y >= TILE_SIZE:
				continue
			var fx: float = float(abs(x - cx)) / float(hw)
			var fy: float = float(abs(y - cy)) / float(hh)
			if fx + fy <= 1.0:
				img.set_pixel(x, y, color)

func _fill_triangle(img: Image, ax: int, ay: int, bx: int, by: int, cx2: int, cy2: int, color: Color) -> void:
	var min_x: int = mini(mini(ax, bx), cx2)
	var max_x: int = maxi(maxi(ax, bx), cx2)
	var min_y: int = mini(mini(ay, by), cy2)
	var max_y: int = maxi(maxi(ay, by), cy2)
	for px in range(min_x, max_x + 1):
		for py in range(min_y, max_y + 1):
			if px < 0 or px >= TILE_SIZE or py < 0 or py >= TILE_SIZE:
				continue
			if _point_in_tri(px, py, ax, ay, bx, by, cx2, cy2):
				img.set_pixel(px, py, color)

func _point_in_tri(px: int, py: int, ax: int, ay: int, bx: int, by: int, cx2: int, cy2: int) -> bool:
	var d1: int   = (px - bx) * (ay - by) - (ax - bx) * (py - by)
	var d2: int   = (px - cx2) * (by - cy2) - (bx - cx2) * (py - cy2)
	var d3: int   = (px - ax) * (cy2 - ay) - (cx2 - ax) * (py - ay)
	var has_neg: bool = d1 < 0 or d2 < 0 or d3 < 0
	var has_pos: bool = d1 > 0 or d2 > 0 or d3 > 0
	return not (has_neg and has_pos)

func _draw_border(img: Image, color: Color) -> void:
	for i in TILE_SIZE:
		img.set_pixel(i, 0,             color)
		img.set_pixel(i, TILE_SIZE - 1, color)
		img.set_pixel(0, i,             color)
		img.set_pixel(TILE_SIZE - 1, i, color)

# ── World generation ───────────────────────────────────────────────────────────

func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed if world_seed != 0 else randi()

	var stone_noise  := _make_noise(rng.randi(), 0.06,  3)
	var iron_noise   := _make_noise(rng.randi(), 0.07,  3)
	var coal_noise   := _make_noise(rng.randi(), 0.07,  3)
	var copper_noise := _make_noise(rng.randi(), 0.065, 3)

	_tile_grid.resize(WORLD_SIZE)
	for x in WORLD_SIZE:
		_tile_grid[x] = []
		_tile_grid[x].resize(WORLD_SIZE)

	for x in WORLD_SIZE:
		for y in WORLD_SIZE:
			var wx: int = x - HALF
			var wy: int = y - HALF
			var type: TileTypes.Type

			var dist: float        = Vector2(wx, wy).length()
			var dist_factor: float = clamp(dist / SCALE_DISTANCE, 0.0, 1.0)
			var bonus: float       = dist_factor * SCALE_AMOUNT

			var iron:   float = iron_noise.get_noise_2d(wx, wy)
			var coal:   float = coal_noise.get_noise_2d(wx, wy)
			var stone:  float = stone_noise.get_noise_2d(wx, wy)
			var copper: float = copper_noise.get_noise_2d(wx, wy)

			if iron > IRON_THRESHOLD - bonus:
				type = TileTypes.Type.IRON
			elif coal > COAL_THRESHOLD - bonus:
				type = TileTypes.Type.COAL
			elif copper > COPPER_THRESHOLD - bonus:
				type = TileTypes.Type.COPPER
			elif stone > STONE_THRESHOLD - bonus:
				type = TileTypes.Type.STONE
			else:
				type = TileTypes.Type.GROUND

			if dist < 8.0:
				type = TileTypes.Type.GROUND

			_tile_grid[x][y] = type
			_tile_map.set_cell(Vector2i(wx, wy), _source_ids[type], Vector2i(0, 0))

func _make_noise(seed: int, frequency: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed            = seed
	n.frequency       = frequency
	n.fractal_octaves = octaves
	n.noise_type      = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	return n

# ── Public helpers ─────────────────────────────────────────────────────────────

func get_tile(world_pos: Vector2) -> TileTypes.Type:
	var cell := _tile_map.local_to_map(world_pos)
	var x    := cell.x + HALF
	var y    := cell.y + HALF
	if x < 0 or y < 0 or x >= WORLD_SIZE or y >= WORLD_SIZE:
		return TileTypes.Type.GROUND
	return _tile_grid[x][y]

func get_tile_cell(cell: Vector2i) -> TileTypes.Type:
	var x := cell.x + HALF
	var y := cell.y + HALF
	if x < 0 or y < 0 or x >= WORLD_SIZE or y >= WORLD_SIZE:
		return TileTypes.Type.GROUND
	return _tile_grid[x][y]

func get_source_id(type: TileTypes.Type) -> int:
	return _source_ids.get(type, 0)
