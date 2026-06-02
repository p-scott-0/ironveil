extends Node

# Player inventory — dictionary of item_id -> quantity
var items: Dictionary = {}

signal inventory_changed

func add_item(item_id: String, amount: int = 1) -> void:
	items[item_id] = items.get(item_id, 0) + amount
	inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	items[item_id] -= amount
	if items[item_id] <= 0:
		items.erase(item_id)
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return items.get(item_id, 0) >= amount

func get_count(item_id: String) -> int:
	return items.get(item_id, 0)
