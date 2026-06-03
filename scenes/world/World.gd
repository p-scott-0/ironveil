extends Node2D

const ItemPopupScene := preload("res://scenes/world/ItemPopup.gd")

@onready var tile_map:  TileMapLayer   = $TileMapLayer
@onready var generator: WorldGenerator = $WorldGenerator

func _ready() -> void:
	generator.setup(tile_map)
	MiningSystem.setup(tile_map)
	MiningSystem.tile_mined.connect(_on_tile_mined)
	SaveManager.load_save()

func _on_tile_mined(tile_pos: Vector2i, item_id: String) -> void:
	var popup := Label.new()
	popup.set_script(ItemPopupScene)
	add_child(popup)
	var world_pos := tile_map.map_to_local(tile_pos)
	popup.setup(item_id, world_pos)
