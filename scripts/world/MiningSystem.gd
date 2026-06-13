extends Node

# How many game ticks between each mining hit
const TICKS_PER_HIT := 3

signal mining_started(tile_pos: Vector2i, tile_type: int)
signal mining_stopped
signal mining_hit(tile_pos: Vector2i, hits_done: int, hits_needed: int)
signal tile_mined(tile_pos: Vector2i, item_id: String)

var is_mining:       bool     = false
var target_cell:     Vector2i = Vector2i.ZERO
var target_world_pos: Vector2  = Vector2.ZERO
var _hits_done:      int      = 0
var _hits_needed:    int      = 0
var _tick_counter:   int      = 0

var _tile_map: TileMapLayer   # set by World on _ready

func setup(tile_map: TileMapLayer) -> void:
	_tile_map = tile_map
	GameManager.on_tick.connect(_on_tick)

# Called by Player when a world position is tapped
func try_mine(world_pos: Vector2) -> void:
	var cell := _tile_map.local_to_map(world_pos)
	var type  := _get_type(cell)

	# Tapping an active mining target cancels it
	if is_mining and cell == target_cell:
		stop_mining()
		return

	# Only mineable tiles
	if TileTypes.HARDNESS.get(type, -1) <= 0:
		stop_mining()
		return

	# Start mining new tile
	is_mining        = true
	target_cell      = cell
	target_world_pos = _tile_map.map_to_local(cell)
	_hits_needed     = TileTypes.HARDNESS[type]
	_hits_done       = 0
	_tick_counter    = 0
	mining_started.emit(target_cell, type)

func stop_mining() -> void:
	if not is_mining:
		return
	is_mining = false
	mining_stopped.emit()

func _on_tick(tick: int) -> void:
	if not is_mining:
		return

	_tick_counter += 1
	if _tick_counter < TICKS_PER_HIT:
		return
	_tick_counter = 0

	_hits_done += 1
	mining_hit.emit(target_cell, _hits_done, _hits_needed)

	if _hits_done >= _hits_needed:
		_finish_mining()

func _finish_mining() -> void:
	var type: TileTypes.Type = _get_type(target_cell)
	var item_id: String      = TileTypes.DROP.get(type, "")

	# Resource nodes are infinite — tile stays, just yield the item
	if item_id != "":
		Inventory.add_to_backpack(item_id, 1)
		tile_mined.emit(target_cell, item_id)

	# Reset progress and keep mining automatically
	_hits_done    = 0
	_tick_counter = 0
	mining_hit.emit(target_cell, 0, _hits_needed)  # resets the progress ring

func _get_type(cell: Vector2i) -> TileTypes.Type:
	var src := _tile_map.get_cell_source_id(cell)
	# source IDs were assigned in WorldGenerator in TileTypes.Type order
	if src < 0:
		return TileTypes.Type.GROUND
	return src as TileTypes.Type
