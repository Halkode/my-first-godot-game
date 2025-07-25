extends Node2D

@onready var tilemap: TileMap = $TileMap
@onready var items_container: Node2D = $Items
@onready var player_spawn: Marker2D = $PlayerSpawn

func _ready() -> void:
	print("Basement scene loaded")
	setup_basement_layout()
	spawn_initial_items()

func setup_basement_layout() -> void:
	# Aqui você configuraria o layout do porão usando os assets
	# Por enquanto, apenas um exemplo básico
	print("Setting up basement layout...")
	
	# Exemplo de como você poderia configurar tiles
	# tilemap.set_cell(0, Vector2i(0, 0), 0, Vector2i(0, 0))
	
func spawn_initial_items() -> void:
	# Spawnar itens iniciais no porão
	print("Spawning initial items...")
	
	# Exemplo: spawnar um baú
	spawn_container(Vector2(100, 100), "Baú Velho", "Um baú empoeirado que pode conter algo útil.")
	
	# Exemplo: spawnar uma porta trancada
	spawn_door(Vector2(200, 50), true, "Chave Enferrujada")
	
	# Exemplo: spawnar um trigger de memória
	spawn_memory_trigger(Vector2(50, 150), "memory_01", "Você se lembra vagamente de ter estado aqui antes...")

func spawn_container(pos: Vector2, name: String, description: String) -> void:
	var container = preload("res://scripts/items/container.gd").new()
	container.position = pos
	container.item_name = name
	container.item_description = description
	
	# Adicionar alguns itens aleatórios
	container.populate_with_random_items()
	
	items_container.add_child(container)
	print("Spawned container: ", name, " at ", pos)

func spawn_door(pos: Vector2, locked: bool = false, required_key: String = "") -> void:
	var door = preload("res://scripts/items/door.gd").new()
	door.position = pos
	door.is_locked = locked
	door.required_key = required_key
	
	items_container.add_child(door)
	print("Spawned door at ", pos, " (locked: ", locked, ")")

func spawn_memory_trigger(pos: Vector2, memory_id: String, memory_text: String) -> void:
	var memory_trigger = preload("res://scripts/items/memory_trigger.gd").new()
	memory_trigger.position = pos
	memory_trigger.set_memory_data(memory_id, memory_text)
	
	items_container.add_child(memory_trigger)
	print("Spawned memory trigger: ", memory_id, " at ", pos)

func get_player_spawn_position() -> Vector2:
	return player_spawn.global_position

