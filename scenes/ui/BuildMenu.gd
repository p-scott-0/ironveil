extends HBoxContainer
class_name BuildMenu
# Horizontal building selector. Emits signal when a building type is picked.

signal build_selected(type: String)

const BUILDINGS: Array = [
	{"id": "conveyor",   "icon": "→", "color": Color(0.78, 0.78, 0.82)},
	{"id": "miner",      "icon": "⛏", "color": Color(0.90, 0.65, 0.15)},
	{"id": "smelter",    "icon": "🔥", "color": Color(0.95, 0.38, 0.08)},
	{"id": "fabricator", "icon": "⚙", "color": Color(0.18, 0.82, 0.88)},
	{"id": "assembler",  "icon": "★", "color": Color(0.70, 0.42, 0.96)},
	{"id": "hub",        "icon": "⬡", "color": Color(0.28, 0.90, 0.40)},
	{"id": "splitter",   "icon": "↕", "color": Color(0.62, 0.80, 0.50)},
	{"id": "bridge",     "icon": "⋯", "color": Color(0.40, 0.55, 0.78)},
]

var _selected_id: String = "conveyor"
var _buttons: Array = []

func _ready() -> void:
	for bld in BUILDINGS:
		_add_button(bld)

func _add_button(bld: Dictionary) -> void:
	var btn := Button.new()
	btn.text             = bld["icon"]
	btn.tooltip_text     = bld["id"].capitalize() + \
	                       " (%d mat)" % RecipeBook.get_building_cost(bld["id"])
	btn.custom_minimum_size = Vector2(50, 72)
	btn.add_theme_font_size_override("font_size", 26)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color         = Color(0.08, 0.08, 0.10, 0.85)
	style_normal.border_color     = bld["color"].darkened(0.3)
	style_normal.border_width_left   = 2
	style_normal.border_width_right  = 2
	style_normal.border_width_top    = 2
	style_normal.border_width_bottom = 2
	style_normal.corner_radius_top_left     = 6
	style_normal.corner_radius_top_right    = 6
	style_normal.corner_radius_bottom_left  = 6
	style_normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style_normal)

	var id: String = bld["id"]
	btn.pressed.connect(func(): _select(id, bld["color"]))
	add_child(btn)
	_buttons.append({"btn": btn, "id": id, "color": bld["color"], "style": style_normal})

func _select(id: String, accent: Color) -> void:
	_selected_id = id
	for b in _buttons:
		var s: StyleBoxFlat = b["style"]
		if b["id"] == id:
			s.bg_color     = accent.darkened(0.5)
			s.border_color = accent
		else:
			s.bg_color     = Color(0.08, 0.08, 0.10, 0.85)
			s.border_color = b["color"].darkened(0.3)
		b["btn"].add_theme_stylebox_override("normal", s)
	build_selected.emit(id)

func get_selected() -> String:
	return _selected_id
