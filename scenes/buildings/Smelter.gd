extends Node2D
# 1 input → 1 output via RecipeBook.SMELTER_RECIPES

var cell:      Vector2i = Vector2i.ZERO
var direction: int      = 0

const TICKS_PER_SMELT := 6

const BG_COLOR     := Color(0.16, 0.11, 0.08)
const ACCENT_COLOR := Color(0.95, 0.38, 0.08)

var _input_slot:    String = ""
var _output_slot:   String = ""
var _tick_counter:  int    = 0
var _processing:    bool   = false
var _flame:         float  = 0.0

func setup(c: Vector2i, dir: int) -> void:
	cell      = c
	direction = dir
	queue_redraw()

func _machine_tick(_tick: int) -> void:
	# Try to pull input if slot empty
	if _input_slot == "":
		var in_cells: Array = BuildingManager.get_input_cells(cell, direction, 1)
		if in_cells.size() > 0:
			var item: String = BuildingManager.take_item_from_belt(in_cells[0])
			if item != "":
				var result: String = RecipeBook.get_smelter_output(item)
				if result != "":
					_input_slot   = item
					_output_slot  = result
					_processing   = true
					_tick_counter = 0
				else:
					# Unknown recipe — put item back (drop it)
					BuildingManager.inject_item(in_cells[0], item)

	# Process
	if _processing:
		_tick_counter += 1
		_flame = 1.0
		if _tick_counter >= TICKS_PER_SMELT:
			_finish()

	if _flame > 0.0:
		_flame -= 1.0 / float(TICKS_PER_SMELT)
		_flame = maxf(_flame, 0.0)
	queue_redraw()

func _finish() -> void:
	var out: Vector2i = BuildingManager.get_output_cell(cell, direction)
	if BuildingManager.inject_item(out, _output_slot):
		_input_slot   = ""
		_output_slot  = ""
		_processing   = false
		_tick_counter = 0

func try_accept_item(_item_id: String) -> bool:
	return false  # smelter takes from belt, not via this path

func _draw() -> void:
	var s: float = 14.0
	draw_rect(Rect2(-s, -s, s * 2, s * 2), BG_COLOR)
	draw_rect(Rect2(-s, -s, s * 2, s * 2), ACCENT_COLOR.darkened(0.5), false, 1.5)

	# Flame icon
	if _flame > 0.0:
		var fc: Color = ACCENT_COLOR
		fc.a = _flame
		draw_circle(Vector2(0, 2), 7.0 * _flame + 3.0, fc)
		draw_circle(Vector2(0, -1), 4.0 * _flame + 2.0, Color(1.0, 0.80, 0.20, _flame * 0.8))
	else:
		# Idle: triangle flame silhouette
		var pts := PackedVector2Array([Vector2(0,-8), Vector2(5,4), Vector2(-5,4)])
		draw_colored_polygon(pts, ACCENT_COLOR.darkened(0.4))

	# Progress bar at bottom
	if _processing:
		var prog: float = float(_tick_counter) / float(TICKS_PER_SMELT)
		draw_rect(Rect2(-10, 11, 20, 3), Color(0.2, 0.2, 0.2))
		draw_rect(Rect2(-10, 11, 20.0 * prog, 3), ACCENT_COLOR.lightened(0.3))

	# Output arrow
	var angle: float = [PI * 1.5, 0.0, PI * 0.5, PI][direction]
	draw_colored_polygon(PackedVector2Array([
		Vector2(12.0, 0).rotated(angle),
		Vector2(8.0, -3.0).rotated(angle),
		Vector2(8.0,  3.0).rotated(angle),
	]), ACCENT_COLOR)
