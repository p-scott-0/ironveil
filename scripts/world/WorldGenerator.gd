extends Node
class_name WorldGenerator

const WORLD_SIZE  := 192  # tiles in each axis — expandable to chunk-based later
const TILE_SIZE   := 32
const HALF        := WORLD_SIZE / 2

# Noise thresholds — tweak these to change world feel
const WATER_THRESHOLD  := -0.25
const TREE_THRESHOLD   := 0.45
const STONE_THRESHOLD  := 0.55
const IRON_THRESHOLD   := 0.60
const COAL_THRESHOLD   := 0.58

@export var world_seed: int = 0

var _tile_map: TileMapLayer
var _source_ids: Dictionary = {}   # TileTypes.Type -> source_id
var _tile_grid: Array = []         # 2D array [x][y] of TileTypes.Type

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
		source.texture = _make_color_texture(TileTypes.COLORS[type])
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		source.create_tile(Vector2i(0, 0))

		if not TileTypes.PASSABLE[type]:
			var td: TileData = source.get_tile_data(Vector2i(0, 0), 0)
			var half := TILE_SIZE / 2.0
			var poly := PackedVector2Array([
				Vector2(-half, -half),
				Vector2( half, -half),
				Vector2( half,  half),
				Vector2(-half,  half),
			])
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, poly)

		_source_ids[type] = ts.add_source(source)

	_tile_map.tile_set = ts

func _make_color_texture(color: Color) -> ImageTexture:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	# Fill base color
	img.fill(color)
	# Thin dark border so tiles are visually distinct
	var border := color.darkened(0.25)
	for i in TILE_SIZE:
		img.set_pixel(i, 0, border)
		img.set_pixel(i, TILE_SIZE - 1, border)
		img.set_pixel(0, i, border)
		img.set_pixel(TILE_SIZE - 1, i, border)
	return ImageTexture.create_from_image(img)

# ── Generation ─────────────────────────────────────────────────────────────────

func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed if world_seed != 0 else randi()

	# Separate noise layers for each feature
	var terrain_noise := _make_noise(rng.randi(), 0.025, 4)
	var tree_noise    := _make_noise(rng.randi(), 0.08,  3)
	var stone_noise   := _make_noise(rng.randi(), 0.06,  2)
	var iron_noise    := _make_noise(rng.randi(), 0.07,  2)
	var coal_noise    := _make_noise(rng.randi(), 0.07,  2)

	# Initialise grid
	_tile_grid.resize(WORLD_SIZE)
	for x in WORLD_SIZE:
		_tile_grid[x] = []
		_tile_grid[x].resize(WORLD_SIZE)

	for x in WORLD_SIZE:
		for y in WORLD_SIZE:
			var wx := x - HALF
			var wy := y - HALF

			var t   := terrain_noise.get_noise_2d(wx, wy)
			var type: TileTypes.Type

			if t < WATER_THRESHOLD:
				type = TileTypes.Type.WATER
			else:
				# Layered resource placement — priority: iron > coal > stone > tree > ground
				var iron  := iron_noise.get_noise_2d(wx, wy)
				var coal  := coal_noise.get_noise_2d(wx, wy)
				var stone := stone_noise.get_noise_2d(wx, wy)
				var tree  := tree_noise.get_noise_2d(wx, wy)

				if iron > IRON_THRESHOLD:
					type = TileTypes.Type.IRON
				elif coal > COAL_THRESHOLD:
					type = TileTypes.Type.COAL
				elif stone > STONE_THRESHOLD:
					type = TileTypes.Type.STONE
				elif tree > TREE_THRESHOLD:
					type = TileTypes.Type.TREE
				else:
					type = TileTypes.Type.GROUND

			# Keep a clear spawn area (radius 6) so player doesn't spawn in a wall
			var dist := Vector2(wx, wy).length()
			if dist < 6.0:
				type = TileTypes.Type.GROUND

			_tile_grid[x][y] = type
			_tile_map.set_cell(Vector2i(wx, wy), _source_ids[type], Vector2i(0, 0))

func _make_noise(seed: int, frequency: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed         = seed
	n.frequency    = frequency
	n.fractal_octaves = octaves
	n.noise_type   = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	return n

# ── Public helpers ─────────────────────────────────────────────────────────────

func get_tile(world_pos: Vector2) -> TileTypes.Type:
	var cell := _tile_map.local_to_map(world_pos)
	var x := cell.x + HALF
	var y := cell.y + HALF
	if x < 0 or y < 0 or x >= WORLD_SIZE or y >= WORLD_SIZE:
		return TileTypes.Type.WATER
	return _tile_grid[x][y]

func set_tile(world_pos: Vector2, type: TileTypes.Type) -> void:
	var cell := _tile_map.local_to_map(world_pos)
	var x := cell.x + HALF
	var y := cell.y + HALF
	if x < 0 or y < 0 or x >= WORLD_SIZE or y >= WORLD_SIZE:
		return
	_tile_grid[x][y] = type
	_tile_map.set_cell(cell, _source_ids[type], Vector2i(0, 0))
