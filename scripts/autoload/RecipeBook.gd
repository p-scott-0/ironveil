extends Node

# ── Item display data ──────────────────────────────────────────────────────────

const ITEM_NAMES: Dictionary = {
	"stone"             : "Stone",
	"iron_ore"          : "Iron Ore",
	"coal"              : "Coal",
	"copper_ore"        : "Copper Ore",
	"iron_plate"        : "Iron Plate",
	"copper_plate"      : "Copper Plate",
	"building_material" : "Building Material",
	"ammo"              : "Ammo",
}

const ITEM_COLORS: Dictionary = {
	"stone"             : Color(0.58, 0.58, 0.60),
	"iron_ore"          : Color(0.25, 0.45, 0.88),
	"coal"              : Color(0.16, 0.16, 0.18),
	"copper_ore"        : Color(0.92, 0.52, 0.14),
	"iron_plate"        : Color(0.42, 0.62, 0.88),
	"copper_plate"      : Color(0.88, 0.58, 0.24),
	"building_material" : Color(0.28, 0.82, 0.38),
	"ammo"              : Color(0.95, 0.88, 0.18),
}

# circle / square / triangle / diamond
const ITEM_SHAPES: Dictionary = {
	"stone"             : "circle",
	"iron_ore"          : "square",
	"coal"              : "circle",
	"copper_ore"        : "triangle",
	"iron_plate"        : "square",
	"copper_plate"      : "triangle",
	"building_material" : "diamond",
	"ammo"              : "diamond",
}

# ── Recipes ────────────────────────────────────────────────────────────────────

# Smelter: single item in → single item out
const SMELTER_RECIPES: Dictionary = {
	"iron_ore"   : "iron_plate",
	"copper_ore" : "copper_plate",
}

# Fabricator: two items in → single item out.
# Key = the two item IDs sorted alphabetically, joined with "+"
const FABRICATOR_RECIPES: Dictionary = {
	"coal+iron_plate"          : "building_material",
	"copper_plate+iron_plate"  : "ammo",
}

# Assembler: three items in → single item out.
# (expand when higher-tier items are designed)
const ASSEMBLER_RECIPES: Dictionary = {}

# ── Building costs (in building_material) ─────────────────────────────────────

const BUILDING_COSTS: Dictionary = {
	"miner"      : 3,
	"smelter"    : 4,
	"fabricator" : 6,
	"assembler"  : 8,
	"hub"        : 10,
	"splitter"   : 2,
	"bridge"     : 1,
	"conveyor"   : 0,
}

# ── Helpers ────────────────────────────────────────────────────────────────────

func get_item_name(id: String) -> String:
	return ITEM_NAMES.get(id, id)

func get_item_color(id: String) -> Color:
	return ITEM_COLORS.get(id, Color.WHITE)

func get_item_shape(id: String) -> String:
	return ITEM_SHAPES.get(id, "circle")

func get_smelter_output(input: String) -> String:
	return SMELTER_RECIPES.get(input, "")

func get_fabricator_output(a: String, b: String) -> String:
	var pair: Array = [a, b]
	pair.sort()
	return FABRICATOR_RECIPES.get("+".join(pair), "")

func get_assembler_output(a: String, b: String, c: String) -> String:
	var trio: Array = [a, b, c]
	trio.sort()
	return ASSEMBLER_RECIPES.get("+".join(trio), "")

func get_building_cost(type: String) -> int:
	return BUILDING_COSTS.get(type, 0)
