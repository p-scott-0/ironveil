extends Node

enum Type {
	GROUND = 0,
	WATER  = 1,
	STONE  = 2,
	IRON   = 3,
	COAL   = 4,
	TREE   = 5,
}

const COLORS: Dictionary = {
	Type.GROUND : Color(0.47, 0.62, 0.35),
	Type.WATER  : Color(0.25, 0.45, 0.75),
	Type.STONE  : Color(0.55, 0.55, 0.55),
	Type.IRON   : Color(0.78, 0.55, 0.32),
	Type.COAL   : Color(0.18, 0.18, 0.18),
	Type.TREE   : Color(0.13, 0.42, 0.13),
}

# false = blocks movement and bullets
const PASSABLE: Dictionary = {
	Type.GROUND : true,
	Type.WATER  : false,
	Type.STONE  : false,
	Type.IRON   : false,
	Type.COAL   : false,
	Type.TREE   : false,
}

# How many hits to mine, -1 = not mineable
const HARDNESS: Dictionary = {
	Type.GROUND : -1,
	Type.WATER  : -1,
	Type.STONE  : 8,
	Type.IRON   : 12,
	Type.COAL   : 10,
	Type.TREE   : 4,
}

# What item drops when mined
const DROP: Dictionary = {
	Type.STONE : "stone",
	Type.IRON  : "iron_ore",
	Type.COAL  : "coal",
	Type.TREE  : "wood",
}
