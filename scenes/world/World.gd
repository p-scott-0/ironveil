extends Node2D

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var generator: WorldGenerator = $WorldGenerator

func _ready() -> void:
	generator.setup(tile_map)
	SaveManager.load_save()
