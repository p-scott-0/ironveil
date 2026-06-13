extends Node

enum Type {
	GROUND = 0,
	STONE  = 1,
	IRON   = 2,
	COAL   = 3,
	COPPER = 4,
}

const PASSABLE: Dictionary = {
	Type.GROUND : true,
	Type.STONE  : true,
	Type.IRON   : true,
	Type.COAL   : true,
	Type.COPPER : true,
}

# -1 = not minable
const HARDNESS: Dictionary = {
	Type.GROUND : -1,
	Type.STONE  :  5,
	Type.IRON   : 10,
	Type.COAL   :  7,
	Type.COPPER :  8,
}

const DROP: Dictionary = {
	Type.STONE  : "stone",
	Type.IRON   : "iron_ore",
	Type.COAL   : "coal",
	Type.COPPER : "copper_ore",
}
