extends Node2D

@onready var lighting_system: LightingSystem = $LightingSystem

func _ready() -> void:
	print("Inicializando jogo...")
	
	# Aguardar um frame para garantir que todos os nós estejam prontos
	await get_tree().process_frame
	
	# ItemManager, AudioManager, DayNightCycle, NarrativeManager, UIManager são autoloads
	# e podem ser acessados diretamente sem @onready ou get_node
	
	# O LightingSystem é opcional: sem ele o resto da cena ainda deve
	# ser montado, então apenas avisamos em vez de abortar o _ready.
	if lighting_system:
		# O Player se registra no grupo "player" no próprio _ready
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node:
			lighting_system.player_node = player_node
	else:
		push_warning("LightingSystem não encontrado na cena.")


	# Conectar sinais do GameManager ao AudioManager
	GameManager.fear_changed.connect(AudioManager._on_fear_changed)
	GameManager.sanity_changed.connect(AudioManager._on_sanity_changed)

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
	var table1 = ItemManager.add_item_to_tilemap(table_scene, Vector2i(5, 3))
	if table1:
		print("Mesa 1 adicionada com sucesso na posição (5, 3)")
	
	# Adicionar mais mesas em outras posições (opcional)
	var table2 = ItemManager.add_item_to_tilemap(table_scene, Vector2i(8, 5))
	if table2:
		print("Mesa 2 adicionada com sucesso na posição (8, 5)")
	
	var table3 = ItemManager.add_item_to_tilemap(table_scene, Vector2i(3, 7))
	if table3:
		print("Mesa 3 adicionada com sucesso na posição (3, 7)")

func _process(_delta: float) -> void:
	# Você pode adicionar lógica de jogo aqui se necessário
	pass
