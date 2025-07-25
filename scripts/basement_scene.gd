extends Node2D

@onready var tilemaps_node: Node2D = $"TileMaps" # Referência ao nó TileMaps instanciado
@onready var layer0: TileMap = $"TileMaps/Layer0"
@onready var layer1: TileMap = $"TileMaps/Layer1"
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
	# layer0.set_cell(0, Vector2i(0, 0), 0, Vector2i(0, 0))
	
func spawn_initial_items() -> void:
	# Spawnar itens iniciais no porão
	print("Spawning initial items...")
	
	var chest_scene = preload("res://scenes/items/Chest.tscn")
	var door_scene = preload("res://scenes/items/Door.tscn")
	var memory_trigger_scene = preload("res://scenes/items/MemoryTrigger.tscn")
	
	# Item 1: Baú com itens iniciais
	if chest_scene:
		ItemManager.add_item_to_tilemap(chest_scene, Vector2i(5, 3), {"item_name": "Baú Velho", "item_description": "Um baú empoeirado que pode conter algo útil.", "is_locked": false, "container_items": [{"name": "Vela", "description": "Uma vela que pode fornecer luz."}, {"name": "Fósforos", "description": "Uma caixa de fósforos quase vazia."}]})
	
	# Item 2: Porta trancada (requer chave)
	if door_scene:
		ItemManager.add_item_to_tilemap(door_scene, Vector2i(8, 2), {"item_name": "Porta de Ferro", "item_description": "Uma porta de ferro pesada que leva para fora do porão.", "is_locked": true, "required_key": "Chave do Porão"})
	
	# Memória 1: O Despertar no Escuro (próximo ao spawn do player)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(2, 2), {"memory_id": "memory_01", "memory_title": "O Despertar no Escuro", "memory_description": "A escuridão é a primeira coisa que você sente...", "trigger_on_examine": true})
	
	# Memória 2: A Presença Silenciosa (próximo ao corpo)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(4, 2), {"memory_id": "memory_02", "memory_title": "A Presença Silenciosa", "memory_description": "Ao seu lado, uma forma inerte. Um corpo...", "trigger_on_examine": true})
	
	# Memória 3: As Portas Seladas (próximo a uma das portas trancadas)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(7, 2), {"memory_id": "memory_03", "memory_title": "As Portas Seladas", "memory_description": "Você tateia na escuridão, encontrando paredes frias e úmidas. Há portas, mas todas estão trancadas...", "trigger_on_examine": true})
	
	# Memória 4: O Ronco do Vazio (próximo a um local onde se pode encontrar comida)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(6, 5), {"memory_id": "memory_04", "memory_title": "O Ronco do Vazio", "memory_description": "A fome. Uma dor aguda no estômago...", "trigger_on_examine": true})
	
	# Memória 5: Ecos do Passado (próximo a um objeto aleatório, como uma pilha de lixo)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(3, 7), {"memory_id": "memory_05", "memory_title": "Ecos do Passado", "memory_description": "Cada objeto que você toca, cada sombra que dança...", "trigger_on_examine": true})
	
	# Memória 6: A Desintegração da Sanidade (em um canto escuro ou isolado)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(1, 8), {"memory_id": "memory_06", "memory_title": "A Desintegração da Sanidade", "memory_description": "O tempo se torna um borrão. Dias e noites se misturam...", "trigger_on_examine": true})
	
	# Memória 7: Os Olhos na Escuridão (em uma área mais escura ou com inimigos)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(9, 6), {"memory_id": "memory_07", "memory_title": "Os Olhos na Escuridão", "memory_description": "Você não está sozinho. Há algo mais aqui...", "trigger_on_examine": true})
	
	# Memória 8: A Chave Interior (próximo a um quebra-cabeça ou item importante)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(5, 8), {"memory_id": "memory_08", "memory_title": "A Chave Interior", "memory_description": "A fuga não é apenas física. É uma jornada para dentro de si mesmo...", "trigger_on_examine": true})
	
	# Memória 9: Escolhas Amargas (próximo a um evento que envolva uma escolha)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(10, 4), {"memory_id": "memory_09", "memory_title": "Escolhas Amargas", "memory_description": "A cada passo, uma decisão. Cada escolha tem um peso...", "trigger_on_examine": true})
	
	# Memória 10: A Conspiração Silenciosa (em um local de revelação final)
	if memory_trigger_scene:
		ItemManager.add_item_to_tilemap(memory_trigger_scene, Vector2i(1, 5), {"memory_id": "memory_10", "memory_title": "A Conspiração Silenciosa", "memory_description": "A verdade se revela, fragmento por fragmento...", "trigger_on_examine": true})

func get_player_spawn_position() -> Vector2:
	return player_spawn.global_position


