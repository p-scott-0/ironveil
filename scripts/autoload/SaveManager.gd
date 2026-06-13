extends Node

const SAVE_PATH := "user://savegame.json"

func save() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var pos: Dictionary = {}
	if player:
		pos = {"x": player.global_position.x, "y": player.global_position.y}
	var data := {
		"inventory": Inventory.get_save_data(),
		"player_position": pos,
		"tick": GameManager.tick_count,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var result: Variant = JSON.parse_string(file.get_as_text())
	if not result is Dictionary:
		return false
	var data: Dictionary = result
	Inventory.load_save_data(data.get("inventory", {}))
	GameManager.tick_count = data.get("tick", 0)
	return true
