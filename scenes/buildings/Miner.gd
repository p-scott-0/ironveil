extends Node2D
# Placed on a resource tile; extracts items automatically and outputs to a belt.

var cell:      Vector2i = Vector2i.ZERO
var direction: int      = 2  # default output South

const TICKS_PER_ITEM := 5

var _tick_counter:  int    = 0
var _resource_type: TileTypes.Type = TileTypes.Type.GROUND
var _item_id:       String = ""
var _working:       bool   = false
var _flash:         float  = 0.0

const BG_COLOR     := Color(0.12, 0.18, 0.28)
const ACCENT_COLOR := Color(0.90, 0.65, 0.15)

func setup(c: Vector2i, dir: int) -> void:
	cell            = c
	direction       = dir
	_resource_type  = BuildingManager.get_terrain_type(c)
	_item_id        = TileTypes.DROP.get(_resource_type, "")
	_working        = _item_id != ""
	queue_redraw()

func _machine_tick(_tick: int) -> void:
	if not _working:
		return
	_tick_counter += 1
	if _tick_counter >= TICKS_PER_ITEM:
		_tick_counter = 0
		_try_output()

func _try_output() -> void:
	var out_cell: Vector2i = BuildingManager.get_output_cell(cell, direction)
	if BuildingManager.inject_item(out_cell, _item_id):
		_flash = 0.25
		queue_redraw()

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		queue_redraw()

func try_accept_item(_item_id2: String) -> bool:
	return false  # miners don't take input

func _draw() -> void:
	var s: float = 14.0
	draw_rect(Rect2(-s, -s, s * 2, s * 2), BG_COLOR)
	draw_rect(Rect2(-s, -s, s * 2, s * 2), ACCENT_COLOR.darkened(0.5), false, 1.5)

	# Pickaxe cross symbol
	var ax: Color = ACCENT_COLOR if _flash <= 0.0 else Color(1.0, 1.0, 0.6)
	draw_line(Vector2(-6, -6), Vector2(6, 6), ax, 3.0, true)
	draw_line(Vector2(-6, 6), Vector2(6, -6), ax, 1.5, true)

	# Progress ring
	if _working and TICKS_PER_ITEM > 0:
		var prog: float = float(_tick_counter) / float(TICKS_PER_ITEM)
		draw_arc(Vector2.ZERO, 12.0, -PI * 0.5, -PI * 0.5 + TAU * prog,
		         16, ACCENT_COLOR.lightened(0.3), 2.0, true)

	# Output direction arrow
	var angle: float = [PI * 1.5, 0.0, PI * 0.5, PI][direction]
	var tip  := Vector2(12.0, 0).rotated(angle)
	var bl   := Vector2(8.0, -3.0).rotated(angle)
	var br   := Vector2(8.0,  3.0).rotated(angle)
	draw_colored_polygon(PackedVector2Array([tip, bl, br]), ACCENT_COLOR)
