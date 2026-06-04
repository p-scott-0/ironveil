extends Node

enum Type {
	GROUND = 0,
	WATER  = 1,
	STONE  = 2,
	IRON   = 3,
	COAL   = 4,
}

const COLORS: Dictionary = {
	Type.GROUND : Color(0.47, 0.62, 0.35),
	Type.WATER  : Color(0.25, 0.45, 0.75),
	Type.STONE  : Color(0.55, 0.55, 0.55),
	Type.IRON   : Color(0.78, 0.55, 0.32),
	Type.COAL   : Color(0.18, 0.18, 0.18),
}

# false = blocks movement
const PASSABLE: Dictionary = {
	Type.GROUND : true,
	Type.WATER  : false,
	Type.STONE  : false,
	Type.IRON   : false,
	Type.COAL   : false,
}

# Hits per extraction cycle — higher = slower manual mining, same cost for automation
const HARDNESS: Dictionary = {
	Type.GROUND : -1,
	Type.WATER  : -1,
	Type.STONE  : 6,
	Type.IRON   : 10,
	Type.COAL   : 8,
}

# Item yielded per completed cycle
const DROP: Dictionary = {
	Type.STONE : "stone",
	Type.IRON  : "iron_ore",
	Type.COAL  : "coal",
}
