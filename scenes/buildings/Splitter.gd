extends Node2D
# Splits input into up to 3 outputs (round-robin).
# This is a belt-type building handled by BuildingManager's belt system.
# This script exists so BuildingManager can load it — actual logic is in BuildingManager.

var cell:      Vector2i = Vector2i.ZERO
var direction: int      = 1

func setup(c: Vector2i, dir: int) -> void:
	cell      = c
	direction = dir

func try_accept_item(_item_id: String) -> bool:
	return false
