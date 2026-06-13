extends Node2D

@onready var terrain_map:    TileMapLayer = $TerrainMap
@onready var belt_map:       TileMapLayer = $BeltMap
@onready var belt_items:     Node2D       = $BeltItems
@onready var machines:       Node2D       = $Machines
@onready var generator:      WorldGenerator = $WorldGenerator
@onready var mining_indicator: Node2D     = $MiningIndicator

func _ready() -> void:
	# World must be generated before BuildingManager needs terrain data
	generator.setup(terrain_map)
	MiningSystem.setup(terrain_map)
	BuildingManager.setup(belt_map, machines, belt_items, terrain_map)

	MiningSystem.tile_mined.connect(_on_tile_mined)
	SaveManager.load_save()

func _on_tile_mined(tile_pos: Vector2i, item_id: String) -> void:
	# Show a floating "+item" label
	var popup := Label.new()
	popup.text               = "+ " + RecipeBook.get_item_name(item_id)
	popup.add_theme_color_override("font_color", RecipeBook.get_item_color(item_id))
	popup.add_theme_font_size_override("font_size", 20)
	add_child(popup)
	popup.global_position = terrain_map.map_to_local(tile_pos) + Vector2(-30, -20)

	var tween: Tween = create_tween()
	tween.tween_property(popup, "position:y", popup.position.y - 50, 1.0)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.tween_callback(popup.queue_free)
