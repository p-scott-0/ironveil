extends Node2D
# 3 inputs (left, back, right) → 1 output

var cell:      Vector2i = Vector2i.ZERO
var direction: int      = 0

const TICKS_PER_ASSEMBLE := 10

const BG_COLOR     := Color(0.14, 0.08, 0.20)
const ACCENT_COLOR := Color(0.70, 0.42, 0.96)

var _slot_a:       String = ""
var _slot_b:       String = ""
var _slot_c:       String = ""
var _output_slot:  String = ""
var _tick_counter: int    = 0
var _processing:   bool   = false

func setup(c: Vector2i, dir: int) -> void:
	cell      = c
	direction = dir
	queue_redraw()

func _machine_tick(_tick: int) -> void:
	var in_cells: Array = BuildingManager.get_input_cells(cell, direction, 3)
	if in_cells.size() >= 3:
		if _slot_a == "":
			_slot_a = BuildingManager.take_item_from_belt(in_cells[0])
		if _slot_b == "":
			_slot_b = BuildingManager.take_item_from_belt(in_cells[1])
		if _slot_c == "":
			_slot_c = BuildingManager.take_item_from_belt(in_cells[2])

	if not _processing and _slot_a != "" and _slot_b != "" and _slot_c != "":
		var result: String = RecipeBook.get_assembler_output(_slot_a, _slot_b, _slot_c)
		if result != "":
			_output_slot  = result
			_processing   = true
			_tick_counter = 0
		else:
			_slot_a = ""
			_slot_b = ""
			_slot_c = ""

	if _processing:
		_tick_counter += 1
		if _tick_counter >= TICKS_PER_ASSEMBLE:
			_finish()
	queue_redraw()

func _finish() -> void:
	var out: Vector2i = BuildingManager.get_output_cell(cell, direction)
	if BuildingManager.inject_item(out, _output_slot):
		_slot_a = _slot_b = _slot_c = _output_slot = ""
		_processing   = false
		_tick_counter = 0

func try_accept_item(_item_id: String) -> bool:
	return false

func _draw() -> void:
	var s: float = 14.0
	draw_rect(Rect2(-s, -s, s * 2, s * 2), BG_COLOR)
	draw_rect(Rect2(-s, -s, s * 2, s * 2), ACCENT_COLOR.darkened(0.5), false, 1.5)

	# Three interlocking circles
	for i in 3:
		var ang: float = float(i) / 3.0 * TAU - PI * 0.5
		var cp: Vector2 = Vector2(cos(ang), sin(ang)) * 5.0
		draw_circle(cp, 4.5, ACCENT_COLOR.darkened(0.3))
		draw_circle(cp, 2.8, ACCENT_COLOR)

	# Slot dots
	for i in 3:
		var slot: String = [_slot_a, _slot_b, _slot_c][i]
		var col: Color = ACCENT_COLOR.lightened(0.5) if slot != "" else Color(0.3, 0.3, 0.3)
		var ang: float = float(i) / 3.0 * TAU - PI * 0.5
		draw_circle(Vector2(cos(ang), sin(ang)) * 12.0, 2.5, col)

	if _processing:
		var prog: float = float(_tick_counter) / float(TICKS_PER_ASSEMBLE)
		draw_arc(Vector2.ZERO, 12.0, -PI * 0.5, -PI * 0.5 + TAU * prog,
		         20, ACCENT_COLOR.lightened(0.3), 2.0, true)

	var angle: float = [PI * 1.5, 0.0, PI * 0.5, PI][direction]
	draw_colored_polygon(PackedVector2Array([
		Vector2(12.0, 0).rotated(angle),
		Vector2(8.0, -3.0).rotated(angle),
		Vector2(8.0,  3.0).rotated(angle),
	]), ACCENT_COLOR)
