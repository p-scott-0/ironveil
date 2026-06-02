# Ironveil — Claude Mobile Context

You are helping develop **Ironveil**, a 2D factory/crafting game with exploration and light tower defence, similar to Factorio. Built in **Godot 4.6.3** using **GDScript**. Target platform is **iOS** (mobile-first), with PC support via keyboard/mouse.

## How to apply fixes

The user does not know GDScript. When giving a fix:
1. State the exact file path (e.g. `scenes/player/Player.gd`)
2. Show the exact block to find and replace
3. Explain what the fix does in plain English

The user edits files at: **github.com/p-scott-0/ironveil** — tap a file, tap the pencil icon, edit, commit. Every commit auto-builds and deploys to their phone via AltStore.

---

## Project Structure

```
ironveil/
├── scenes/
│   ├── player/Player.gd        — Player movement, health, input
│   ├── ui/HUD.gd               — Health bar + joystick wiring
│   ├── ui/VirtualJoystick.gd   — Touch joystick input
│   └── world/World.gd          — Main scene, runs world gen + save load
├── scripts/
│   ├── autoload/
│   │   ├── GameManager.gd      — Global simulation tick (10/sec)
│   │   ├── Inventory.gd        — Player item storage
│   │   └── SaveManager.gd      — Save/load to JSON
│   ├── player/
│   │   └── HealthComponent.gd  — Health, damage, death signals
│   ├── world/
│   │   ├── TileTypes.gd        — Tile enum, colours, hardness, drops
│   │   └── WorldGenerator.gd   — Procedural noise-based world gen
│   ├── buildings/
│   │   └── BaseBuilding.gd     — Base class all buildings extend
│   └── items/
│       ├── ItemDefinition.gd   — Item resource (id, icon, stack size)
│       └── Recipe.gd           — Crafting recipe resource
```

## Autoloads (global singletons)

- `GameManager` — emits `on_tick` signal at 10 ticks/sec. All machines listen to this instead of `_process`.
- `Inventory` — `add_item(id, amount)`, `remove_item(id, amount)`, `has_item(id, amount)`, `get_count(id)`
- `TileTypes` — enum of tile types: GROUND, WATER, STONE, IRON, COAL, TREE
- `SaveManager` — `save()` and `load_save()`

---

## All Current Scripts

### scenes/player/Player.gd
```gdscript
extends CharacterBody2D

const SPEED := 300.0

var move_direction: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component: Node = $HealthComponent

func _physics_process(_delta: float) -> void:
	var kb := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := (move_direction + kb).normalized() if (move_direction + kb).length() > 0 else Vector2.ZERO
	velocity = dir * SPEED
	move_and_slide()
	if dir != Vector2.ZERO:
		sprite.flip_h = dir.x < 0

func take_damage(amount: int) -> void:
	health_component.take_damage(amount)
```

### scenes/ui/VirtualJoystick.gd
```gdscript
extends Control

signal direction_changed(direction: Vector2)

const DEAD_ZONE := 10.0
const RADIUS := 80.0

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob

var _touch_index: int = -1
var _base_pos: Vector2

func _ready() -> void:
	_base_pos = base.global_position + base.size / 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _is_in_joystick_area(event.position):
			_touch_index = event.index
			_base_pos = event.position
			base.global_position = _base_pos - base.size / 2.0
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var offset := event.position - _base_pos
		var clamped := offset.limit_length(RADIUS)
		knob.position = clamped - knob.size / 2.0 + base.size / 2.0
		var direction := Vector2.ZERO if offset.length() < DEAD_ZONE else clamped / RADIUS
		direction_changed.emit(direction)

func _release() -> void:
	_touch_index = -1
	knob.position = base.size / 2.0 - knob.size / 2.0
	direction_changed.emit(Vector2.ZERO)

func _is_in_joystick_area(pos: Vector2) -> bool:
	return pos.x < get_viewport_rect().size.x / 2.0 and pos.y > get_viewport_rect().size.y * 0.5
```

### scenes/ui/HUD.gd
```gdscript
extends CanvasLayer

@onready var joystick: Control = $VirtualJoystick
@onready var health_bar: ProgressBar = $HealthBar

var player: CharacterBody2D

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		var health: HealthComponent = player.get_node("HealthComponent")
		health.health_changed.connect(_on_health_changed)
		joystick.direction_changed.connect(_on_joystick_moved)
		_on_health_changed(health.current_health, health.max_health)

func _on_joystick_moved(direction: Vector2) -> void:
	if player:
		player.move_direction = direction

func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
```

### scenes/world/World.gd
```gdscript
extends Node2D

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var generator: WorldGenerator = $WorldGenerator

func _ready() -> void:
	generator.setup(tile_map)
	SaveManager.load_save()
```

### scripts/autoload/GameManager.gd
```gdscript
extends Node

const TICK_RATE := 0.1  # 10 ticks per second

var tick_count: int = 0
var _tick_timer: float = 0.0

signal on_tick(tick: int)

func _process(delta: float) -> void:
	_tick_timer += delta
	if _tick_timer >= TICK_RATE:
		_tick_timer -= TICK_RATE
		tick_count += 1
		on_tick.emit(tick_count)
```

### scripts/autoload/Inventory.gd
```gdscript
extends Node

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
```

### scripts/autoload/SaveManager.gd
```gdscript
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
```

### scripts/player/HealthComponent.gd
```gdscript
extends Node
class_name HealthComponent

signal died
signal health_changed(current: int, maximum: int)

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
```

### scripts/world/TileTypes.gd
```gdscript
extends Node

enum Type {
	GROUND = 0, WATER = 1, STONE = 2, IRON = 3, COAL = 4, TREE = 5,
}

const COLORS: Dictionary = {
	Type.GROUND: Color(0.47, 0.62, 0.35), Type.WATER: Color(0.25, 0.45, 0.75),
	Type.STONE: Color(0.55, 0.55, 0.55),  Type.IRON: Color(0.78, 0.55, 0.32),
	Type.COAL: Color(0.18, 0.18, 0.18),   Type.TREE: Color(0.13, 0.42, 0.13),
}

const PASSABLE: Dictionary = {
	Type.GROUND: true,  Type.WATER: false, Type.STONE: false,
	Type.IRON: false,   Type.COAL: false,  Type.TREE: false,
}

const HARDNESS: Dictionary = {
	Type.GROUND: -1, Type.WATER: -1, Type.STONE: 8,
	Type.IRON: 12,   Type.COAL: 10,  Type.TREE: 4,
}

const DROP: Dictionary = {
	Type.STONE: "stone", Type.IRON: "iron_ore",
	Type.COAL: "coal",   Type.TREE: "wood",
}
```

### scripts/world/WorldGenerator.gd
```gdscript
extends Node
class_name WorldGenerator

const WORLD_SIZE := 192
const TILE_SIZE  := 32
const HALF       := WORLD_SIZE / 2

const WATER_THRESHOLD := -0.25
const TREE_THRESHOLD  := 0.45
const STONE_THRESHOLD := 0.55
const IRON_THRESHOLD  := 0.60
const COAL_THRESHOLD  := 0.58

@export var world_seed: int = 0

var _tile_map: TileMapLayer
var _source_ids: Dictionary = {}
var _tile_grid: Array = []

signal generation_complete

func setup(tile_map: TileMapLayer) -> void:
	_tile_map = tile_map
	_build_tileset()
	_generate()
	generation_complete.emit()
```

### scripts/buildings/BaseBuilding.gd
```gdscript
extends Node2D
class_name BaseBuilding

@export var building_id: String = ""
@export var display_name: String = ""

func _ready() -> void:
	GameManager.on_tick.connect(_on_tick)

func _on_tick(_tick: int) -> void:
	pass  # Override in subclasses

func dismantle() -> void:
	GameManager.on_tick.disconnect(_on_tick)
	queue_free()
```

### scripts/items/Recipe.gd
```gdscript
extends Resource
class_name Recipe

@export var result_item: String = ""
@export var result_amount: int = 1
@export var craft_time_ticks: int = 10
@export var ingredients: Dictionary = {}

func can_craft() -> bool:
	for item_id in ingredients:
		if not Inventory.has_item(item_id, ingredients[item_id]):
			return false
	return true

func consume_ingredients() -> void:
	for item_id in ingredients:
		Inventory.remove_item(item_id, ingredients[item_id])
```

---

## Key design rules
- **No _process in buildings** — everything runs via `GameManager.on_tick` at 10 ticks/sec
- **Mobile-first input** — touch joystick on left half of screen, interaction on right
- **TileTypes is an autoload** — reference as `TileTypes.Type.STONE` etc from anywhere
- **WorldGenerator.get_tile(world_pos)** and **set_tile(world_pos, type)** are the API for reading/changing tiles
- **Player is in group "player"** — find it with `get_tree().get_first_node_in_group("player")`
