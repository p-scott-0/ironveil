extends Node2D
# A small visual item travelling on a conveyor belt.

var item_id: String = ""

func setup(id: String) -> void:
	item_id = id
	queue_redraw()

func _draw() -> void:
	if item_id == "":
		return
	var color: Color = RecipeBook.get_item_color(item_id)
	var shape: String = RecipeBook.get_item_shape(item_id)

	match shape:
		"circle":
			draw_circle(Vector2.ZERO, 6.5, color)
			draw_circle(Vector2(-2, -2), 2.0, color.lightened(0.35))
		"square":
			draw_rect(Rect2(-5.5, -5.5, 11, 11), color)
			draw_rect(Rect2(-3.5, -3.5, 5, 5), color.lightened(0.30))
		"triangle":
			draw_colored_polygon(
				PackedVector2Array([Vector2(0,-7), Vector2(6.5,5), Vector2(-6.5,5)]),
				color)
			draw_colored_polygon(
				PackedVector2Array([Vector2(0,-3), Vector2(3,4), Vector2(-3,4)]),
				color.lightened(0.30))
		"diamond":
			draw_colored_polygon(
				PackedVector2Array([Vector2(0,-7), Vector2(6,0), Vector2(0,7), Vector2(-6,0)]),
				color)
			draw_colored_polygon(
				PackedVector2Array([Vector2(0,-3.5), Vector2(3,0), Vector2(0,3.5), Vector2(-3,0)]),
				color.lightened(0.30))
