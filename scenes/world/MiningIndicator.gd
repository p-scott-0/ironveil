extends Node2D

const TILE_SIZE  := 32.0
const ARC_WIDTH  := 4.0
const RADIUS     := 18.0
const BG_COLOR   := Color(0.0, 0.0, 0.0, 0.45)
const FG_COLOR   := Color(0.95, 0.85, 0.2, 0.9)
const DONE_COLOR := Color(0.3, 1.0, 0.4, 0.9)

var _progress: float = 0.0  # 0.0 → 1.0

func _ready() -> void:
	MiningSystem.mining_hit.connect(_on_hit)
	MiningSystem.mining_stopped.connect(_on_stopped)
	MiningSystem.mining_started.connect(_on_started)

func _on_started(tile_pos: Vector2i, _type: int) -> void:
	# Snap to the centre of the mined tile (world space)
	var tile_map: TileMapLayer = get_parent().get_node("TerrainMap")
	global_position = tile_map.map_to_local(tile_pos)
	_progress = 0.0
	visible   = true
	queue_redraw()

func _on_hit(_tile_pos: Vector2i, hits_done: int, hits_needed: int) -> void:
	_progress = float(hits_done) / float(hits_needed)
	queue_redraw()

func _on_stopped() -> void:
	visible = false
	queue_redraw()

func _draw() -> void:
	if not visible:
		return

	# Background arc (full circle)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, BG_COLOR, ARC_WIDTH, true)

	# Foreground arc (progress)
	if _progress > 0.0:
		var color := DONE_COLOR if _progress >= 1.0 else FG_COLOR
		draw_arc(
			Vector2.ZERO,
			RADIUS,
			-PI / 2.0,
			-PI / 2.0 + TAU * _progress,
			max(4, int(32 * _progress)),
			color,
			ARC_WIDTH,
			true
		)

	# Crosshair lines on the tile
	var h := TILE_SIZE * 0.35
	draw_line(Vector2(-h, 0), Vector2(h, 0),  BG_COLOR, 1.0)
	draw_line(Vector2(0, -h), Vector2(0,  h), BG_COLOR, 1.0)
