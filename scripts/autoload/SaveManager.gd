extends Node

const SAVE_PATH := "user://savegame.json"

func save() -> void:
	var data := {
		"inventory": Inventory.items,
		"player_position": _vec2_to_dict(get_tree().get_first_node_in_group("player").global_position),
		"tick": GameManager.tick_count,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	Inventory.items = data.get("inventory", {})
	GameManager.tick_count = data.get("tick", 0)
	return true

func _vec2_to_dict(v: Vector2) -> Dictionary:
	return {"x": v.x, "y": v.y}

func _dict_to_vec2(d: Dictionary) -> Vector2:
	return Vector2(d.x, d.y)
