extends Node2D

@onready var item_manager: ItemManager = $ItemManager
@onready var lighting_system: LightingSystem = $LightingSystem
@onready var audio_manager: AudioManager = $AudioManager

func _ready() -> void:
	print("Inicializando jogo...")
	
	# Aguardar um frame para garantir que todos os nós estejam prontos
	await get_tree().process_frame
	
	# Verificar se o ItemManager existe
	if not item_manager:
		print("ERRO: ItemManager não encontrado! Certifique-se de que foi adicionado à cena.")
		return
	
	# Verificar se o LightingSystem existe
	if not lighting_system:
		print("ERRO: LightingSystem não encontrado! Certifique-se de que foi adicionado à cena.")
		return
	
	# Verificar se o AudioManager existe
	if not audio_manager:
		print("ERRO: AudioManager não encontrado! Certifique-se de que foi adicionado à cena.")
		return
	
	# Adicionar o player ao grupo "player" para o LightingSystem
	var player_node = get_node_or_null("TileMaps/Player")
	if player_node:
		player_node.add_to_group("player")
		lighting_system.player_node = player_node
		
	# Adicionar o GameManager ao grupo "game_manager"
	var game_manager_node = get_node_or_null("/root/game_manager")
	if game_manager_node:
		game_manager_node.add_to_group("game_manager")
		lighting_system.game_manager = game_manager_node
		
		# Conectar sinais do GameManager ao AudioManager
		game_manager_node.fear_changed.connect(audio_manager._on_fear_changed)
		game_manager_node.sanity_changed.connect(audio_manager._on_sanity_changed)

	# Carregar e adicionar itens ao jogo
	setup_items()

func setup_items() -> void:
	print("Configurando itens...")
	
	# Carregar a cena da mesa
	var table_scene = preload("res://scenes/items/Table.tscn")
	
	if not table_scene:
		print("ERRO: Não foi possível carregar Table.tscn")
		return
	
	# Adicionar uma mesa na posição (5, 3) do tilemap
	var table1 = item_manager.add_item_to_tilemap(table_scene, Vector2i(5, 3))
	if table1:
		print("Mesa 1 adicionada com sucesso na posição (5, 3)")
	
	# Adicionar mais mesas em outras posições (opcional)
	var table2 = item_manager.add_item_to_tilemap(table_scene, Vector2i(8, 5))
	if table2:
		print("Mesa 2 adicionada com sucesso na posição (8, 5)")
	
	var table3 = item_manager.add_item_to_tilemap(table_scene, Vector2i(3, 7))
	if table3:
		print("Mesa 3 adicionada com sucesso na posição (3, 7)")

func _process(delta: float) -> void:
	# Você pode adicionar lógica de jogo aqui se necessário
	pass


