extends Node2D
# 2 inputs (left + right of output) → 1 output

var cell:      Vector2i = Vector2i.ZERO
var direction: int      = 0

const TICKS_PER_CRAFT := 8

const BG_COLOR     := Color(0.08, 0.18, 0.22)
const ACCENT_COLOR := Color(0.18, 0.82, 0.88)

var _slot_a:       String = ""
var _slot_b:       String = ""
var _output_slot:  String = ""
var _tick_counter: int    = 0
var _processing:   bool   = false

func setup(c: Vector2i, dir: int) -> void:
	cell      = c
	direction = dir
	queue_redraw()

func _machine_tick(_tick: int) -> void:
	# Try to fill empty input slots from side belts
	var in_cells: Array = BuildingManager.get_input_cells(cell, direction, 2)
	if in_cells.size() >= 2:
		if _slot_a == "":
			var item: String = BuildingManager.take_item_from_belt(in_cells[0])
			if item != "":
				_slot_a = item
		if _slot_b == "":
			var item: String = BuildingManager.take_item_from_belt(in_cells[1])
			if item != "":
				_slot_b = item

	# Start processing when both slots have matching recipe
	if not _processing and _slot_a != "" and _slot_b != "":
		var result: String = RecipeBook.get_fabricator_output(_slot_a, _slot_b)
		if result != "":
			_output_slot  = result
			_processing   = true
			_tick_counter = 0
		else:
			# Mismatch — clear one slot to try fresh combination
			_slot_a = ""

	if _processing:
		_tick_counter += 1
		if _tick_counter >= TICKS_PER_CRAFT:
			_finish()
	queue_redraw()

func _finish() -> void:
	var out: Vector2i = BuildingManager.get_output_cell(cell, direction)
	if BuildingManager.inject_item(out, _output_slot):
		_slot_a       = ""
		_slot_b       = ""
		_output_slot  = ""
		_processing   = false
		_tick_counter = 0

func try_accept_item(_item_id: String) -> bool:
	return false

func _draw() -> void:
	var s: float = 14.0
	draw_rect(Rect2(-s, -s, s * 2, s * 2), BG_COLOR)
	draw_rect(Rect2(-s, -s, s * 2, s * 2), ACCENT_COLOR.darkened(0.5), false, 1.5)

	# Gear-ish: two interlocking circles
	draw_circle(Vector2(-4, 0), 5.0, ACCENT_COLOR.darkened(0.2))
	draw_circle(Vector2( 4, 0), 5.0, ACCENT_COLOR.darkened(0.2))
	draw_circle(Vector2(-4, 0), 3.0, ACCENT_COLOR)
	draw_circle(Vector2( 4, 0), 3.0, ACCENT_COLOR)

	# Slot indicators
	var a_col: Color = ACCENT_COLOR.lightened(0.4) if _slot_a != "" else Color(0.3, 0.3, 0.3)
	var b_col: Color = ACCENT_COLOR.lightened(0.4) if _slot_b != "" else Color(0.3, 0.3, 0.3)
	draw_circle(Vector2(-9, -9), 3.0, a_col)
	draw_circle(Vector2( 9, -9), 3.0, b_col)

	# Progress arc
	if _processing:
		var prog: float = float(_tick_counter) / float(TICKS_PER_CRAFT)
		draw_arc(Vector2.ZERO, 12.0, -PI * 0.5, -PI * 0.5 + TAU * prog,
		         16, ACCENT_COLOR.lightened(0.3), 2.0, true)

	# Output arrow
	var angle: float = [PI * 1.5, 0.0, PI * 0.5, PI][direction]
	draw_colored_polygon(PackedVector2Array([
		Vector2(12.0, 0).rotated(angle),
		Vector2(8.0, -3.0).rotated(angle),
		Vector2(8.0,  3.0).rotated(angle),
	]), ACCENT_COLOR)
