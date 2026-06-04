extends Node
class_name WorldGenerator

const WORLD_SIZE := 192
const TILE_SIZE  := 32
const HALF       := WORLD_SIZE / 2

# Base noise thresholds (at spawn distance)
const WATER_THRESHOLD := -0.25
const STONE_THRESHOLD := 0.55
const IRON_THRESHOLD  := 0.62
const COAL_THRESHOLD  := 0.60

# How quickly patches grow with distance from spawn.
# At SCALE_DISTANCE tiles out, threshold is reduced by SCALE_AMOUNT
# making patches bigger and more frequent.
const SCALE_DISTANCE := 50.0   # tiles — full scaling kicks in here
const SCALE_AMOUNT   := 0.30   # max threshold reduction at full distance

@export var world_seed: int = 0

var _tile_map:    TileMapLayer
var _source_ids:  Dictionary = {}  # TileTypes.Type -> source_id
var _tile_grid:   Array       = []  # 2D [x][y] of TileTypes.Type

signal generation_complete

func setup(tile_map: TileMapLayer) -> void:
	_tile_map = tile_map
	_build_tileset()
	_generate()
	generation_complete.emit()

# ── Tileset ────────────────────────────────────────────────────────────────────

func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_physics_layer(0)

	for type in TileTypes.Type.values():
		var source := TileSetAtlasSource.new()
		source.texture = _make_tile_texture(type)
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		source.create_tile(Vector2i(0, 0))

		# Add to TileSet FIRST so TileData knows about physics layers
		_source_ids[type] = ts.add_source(source)

		if not TileTypes.PASSABLE[type]:
			var td: TileData = source.get_tile_data(Vector2i(0, 0), 0)
			var half := TILE_SIZE / 2.0
			var poly  := PackedVector2Array([
				Vector2(-half, -half), Vector2( half, -half),
				Vector2( half,  half), Vector2(-half,  half),
			])
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, poly)

	_tile_map.tile_set = ts

# ── Tile textures ──────────────────────────────────────────────────────────────

func _make_tile_texture(type: TileTypes.Type) -> ImageTexture:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)

	match type:
		TileTypes.Type.GROUND:
			_draw_ground(img)
		TileTypes.Type.WATER:
			_draw_water(img)
		TileTypes.Type.STONE:
			_draw_ore(img, Color(0.58, 0.58, 0.60), Color(0.72, 0.72, 0.74))
		TileTypes.Type.IRON:
			_draw_ore(img, Color(0.58, 0.22, 0.06), Color(0.88, 0.48, 0.15))
		TileTypes.Type.COAL:
			_draw_ore(img, Color(0.14, 0.14, 0.16), Color(0.32, 0.32, 0.35))

	return ImageTexture.create_from_image(img)

func _draw_ground(img: Image) -> void:
	var base   := Color(0.47, 0.62, 0.35)
	var detail := base.darkened(0.12)
	img.fill(base)
	# Subtle random-ish texture dots
	for pos in [[4,7],[10,3],[18,12],[25,6],[8,20],[21,24],[14,17],[28,14],[6,26],[24,28]]:
		img.set_pixel(pos[0], pos[1], detail)
	_draw_border(img, base)

func _draw_water(img: Image) -> void:
	var base  := Color(0.25, 0.45, 0.75)
	var light := base.lightened(0.15)
	img.fill(base)
	# Horizontal wave lines
	for x in range(2, 30):
		var y: int = 10 + (2 if x % 8 < 4 else 0)
		img.set_pixel(x, y,     light)
		img.set_pixel(x, y + 1, light)
		var y2: int = 22 + (2 if x % 8 < 4 else 0)
		img.set_pixel(x, y2,     light)
		img.set_pixel(x, y2 + 1, light)
	_draw_border(img, base)

func _draw_ore(img: Image, ore_dark: Color, ore_light: Color) -> void:
	# Ore tiles use the ore colour as the base — no green ground peeking through
	img.fill(ore_dark)

	# Six larger 7×7 nuggets spread across the full tile
	var nuggets: Array = [
		[2,  2],  [13, 1],  [22, 2],
		[1, 14],  [13,14],  [22,14],
	]
	for n in nuggets:
		var ox: int = n[0]
		var oy: int = n[1]
		for dx in range(7):
			for dy in range(7):
				# Round corners
				var corner := (dx == 0 or dx == 6) and (dy == 0 or dy == 6)
				if corner:
					continue
				# Top-left pixel is highlight, rest is mid-tone between dark and light
				var c: Color
				if dx == 1 and dy == 1:
					c = ore_light
				elif dx <= 2 and dy <= 2:
					c = ore_dark.lerp(ore_light, 0.5)
				else:
					c = ore_dark.lerp(ore_light, 0.25)
				img.set_pixel(ox + dx, oy + dy, c)

	# Thin gap lines between nugget rows/columns (ground-coloured cracks)
	var crack := ore_dark.darkened(0.3)
	for i in range(1, 31):
		img.set_pixel(i, 10, crack)
		img.set_pixel(i, 22, crack)
		img.set_pixel(10, i, crack)
		img.set_pixel(21, i, crack)

	# Mineable indicator: small bright dot cluster top-right
	var icon := Color(1.0, 1.0, 0.75, 0.9)
	img.set_pixel(27, 4, icon)
	img.set_pixel(28, 5, icon)
	img.set_pixel(26, 5, icon)
	img.set_pixel(27, 6, icon)

	_draw_border(img, ore_dark)

func _draw_border(img: Image, base: Color) -> void:
	var border := base.darkened(0.22)
	for i in TILE_SIZE:
		img.set_pixel(i, 0,             border)
		img.set_pixel(i, TILE_SIZE - 1, border)
		img.set_pixel(0, i,             border)
		img.set_pixel(TILE_SIZE - 1, i, border)

# ── Generation ─────────────────────────────────────────────────────────────────

func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed if world_seed != 0 else randi()

	var terrain_noise := _make_noise(rng.randi(), 0.025, 4)
	var stone_noise   := _make_noise(rng.randi(), 0.06,  3)
	var iron_noise    := _make_noise(rng.randi(), 0.07,  3)
	var coal_noise    := _make_noise(rng.randi(), 0.07,  3)

	_tile_grid.resize(WORLD_SIZE)
	for x in WORLD_SIZE:
		_tile_grid[x] = []
		_tile_grid[x].resize(WORLD_SIZE)

	for x in WORLD_SIZE:
		for y in WORLD_SIZE:
			var wx  := x - HALF
			var wy  := y - HALF
			var t   := terrain_noise.get_noise_2d(wx, wy)
			var type: TileTypes.Type

			if t < WATER_THRESHOLD:
				type = TileTypes.Type.WATER
			else:
				# Distance from spawn drives patch abundance.
				# Closer to spawn = small/rare patches (safe clearing zone).
				# Further out = larger, denser patches (reward exploration).
				var dist: float        = Vector2(wx, wy).length()
				var dist_factor: float = clamp(dist / SCALE_DISTANCE, 0.0, 1.0)
				var bonus: float       = dist_factor * SCALE_AMOUNT

				var iron  := iron_noise.get_noise_2d(wx, wy)
				var coal  := coal_noise.get_noise_2d(wx, wy)
				var stone := stone_noise.get_noise_2d(wx, wy)

				if iron > IRON_THRESHOLD - bonus:
					type = TileTypes.Type.IRON
				elif coal > COAL_THRESHOLD - bonus:
					type = TileTypes.Type.COAL
				elif stone > STONE_THRESHOLD - bonus:
					type = TileTypes.Type.STONE
				else:
					type = TileTypes.Type.GROUND

			# Clear spawn area so player doesn't start boxed in
			var spawn_dist := Vector2(wx, wy).length()
			if spawn_dist < 8.0:
				type = TileTypes.Type.GROUND

			_tile_grid[x][y] = type
			_tile_map.set_cell(Vector2i(wx, wy), _source_ids[type], Vector2i(0, 0))

func _make_noise(seed: int, frequency: float, octaves: int) -> FastNoiseLite:
	var n               := FastNoiseLite.new()
	n.seed              = seed
	n.frequency         = frequency
	n.fractal_octaves   = octaves
	n.noise_type        = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	return n

# ── Public helpers ─────────────────────────────────────────────────────────────

func get_tile(world_pos: Vector2) -> TileTypes.Type:
	var cell := _tile_map.local_to_map(world_pos)
	var x    := cell.x + HALF
	var y    := cell.y + HALF
	if x < 0 or y < 0 or x >= WORLD_SIZE or y >= WORLD_SIZE:
		return TileTypes.Type.WATER
	return _tile_grid[x][y]

func set_tile(world_pos: Vector2, type: TileTypes.Type) -> void:
	var cell := _tile_map.local_to_map(world_pos)
	var x    := cell.x + HALF
	var y    := cell.y + HALF
	if x < 0 or y < 0 or x >= WORLD_SIZE or y >= WORLD_SIZE:
		return
	_tile_grid[x][y] = type
	_tile_map.set_cell(cell, _source_ids[type], Vector2i(0, 0))
