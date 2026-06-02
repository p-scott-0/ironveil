extends Resource
class_name Recipe

@export var result_item: String = ""
@export var result_amount: int = 1
@export var craft_time_ticks: int = 10  # in simulation ticks
@export var ingredients: Dictionary = {}  # item_id -> amount

func can_craft() -> bool:
	for item_id in ingredients:
		if not Inventory.has_item(item_id, ingredients[item_id]):
			return false
	return true

func consume_ingredients() -> void:
	for item_id in ingredients:
		Inventory.remove_item(item_id, ingredients[item_id])
