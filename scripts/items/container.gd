class_name Container
extends Item

@export var is_locked: bool = false
@export var required_key: String = ""
@export var is_open: bool = false
@export var container_items: Array[Dictionary] = []
@export var max_items: int = 5
@export var open_sprite: Texture2D
@export var closed_sprite: Texture2D

signal container_opened
signal container_closed
signal item_taken_from_container(item_data: Dictionary)

func _ready() -> void:
	super._ready()
	
	# Configurar propriedades específicas do contêiner
	item_name = "Baú"
	item_description = "Um baú de madeira antigo."
	
	# Configurar ações disponíveis baseadas no estado
	update_available_actions()
	
	# Configurar sprite inicial
	update_sprite()

func update_available_actions() -> void:
	actions.clear()
	actions.append("Examinar")
	
	if is_locked:
		if GameManager.has_item(required_key) and required_key != "":
			actions.append("Destrancar")
		else:
			actions.append("Tentar abrir")
	else:
		if is_open:
			actions.append("Fechar")
			if container_items.size() > 0:
				actions.append("Vasculhar")
		else:
			actions.append("Abrir")

func update_sprite() -> void:
	if sprite:
		if is_open and open_sprite:
			sprite.texture = open_sprite
		elif not is_open and closed_sprite:
			sprite.texture = closed_sprite

func interact(player: Node2D) -> void:
	# Atualizar ações disponíveis antes de mostrar o menu
	update_available_actions()
	super.interact(player)

func handle_action(action: String) -> void:
	match action:
		"Abrir":
			open_container()
		"Fechar":
			close_container()
		"Destrancar":
			unlock_container()
		"Tentar abrir":
			try_open_locked_container()
		"Vasculhar":
			search_container()
		"Examinar":
			examine_container()

func open_container() -> void:
	if is_locked:
		GameManager.display_message("O " + item_name.to_lower() + " está trancado.")
		return
	
	if is_open:
		GameManager.display_message("O " + item_name.to_lower() + " já está aberto.")
		return
	
	is_open = true
	update_sprite()
	update_available_actions()
	container_opened.emit()
	
	if container_items.size() > 0:
		GameManager.display_message("Você abriu o " + item_name.to_lower() + ". Há itens dentro!")
	else:
		GameManager.display_message("Você abriu o " + item_name.to_lower() + ". Está vazio.")
	
	print("Contêiner aberto!")

func close_container() -> void:
	if not is_open:
		GameManager.display_message("O " + item_name.to_lower() + " já está fechado.")
		return
	
	is_open = false
	update_sprite()
	update_available_actions()
	container_closed.emit()
	GameManager.display_message("Você fechou o " + item_name.to_lower() + ".")
	print("Contêiner fechado!")

func unlock_container() -> void:
	if not is_locked:
		GameManager.display_message("O " + item_name.to_lower() + " não está trancado.")
		return
	
	if required_key == "" or GameManager.has_item(required_key):
		is_locked = false
		update_available_actions()
		GameManager.display_message("Você destrancou o " + item_name.to_lower() + ".")
		
		# Remover a chave do inventário se necessário
		if required_key != "":
			GameManager.remove_item_from_inventory(required_key)
		
		print("Contêiner destrancado!")
	else:
		GameManager.display_message("Você precisa de uma chave para destrancar este " + item_name.to_lower() + ".")

func try_open_locked_container() -> void:
	GameManager.display_message("O " + item_name.to_lower() + " está trancado. Você precisa de uma chave.")
	GameManager.increase_fear(3)  # Frustração leve aumenta o medo
	print("Tentativa de abrir contêiner trancado!")

func search_container() -> void:
	if not is_open:
		GameManager.display_message("Você precisa abrir o " + item_name.to_lower() + " primeiro.")
		return
	
	if container_items.size() == 0:
		GameManager.display_message("O " + item_name.to_lower() + " está vazio.")
		return
	
	# Pegar o primeiro item disponível
	var item_to_take = container_items[0]
	if GameManager.add_item_to_inventory(item_to_take):
		container_items.remove_at(0)
		item_taken_from_container.emit(item_to_take)
		GameManager.display_message("Você encontrou: " + item_to_take.get("name", "Item desconhecido"))
		
		# Atualizar ações disponíveis
		update_available_actions()
		
		# Pequeno boost de sanidade por encontrar algo útil
		GameManager.modify_sanity(2)
	else:
		GameManager.display_message("Seu inventário está cheio!")

func examine_container() -> void:
	var description = item_description
	
	if is_locked:
		description += " Está trancado."
		if required_key != "":
			description += " Parece precisar de uma chave específica."
	elif is_open:
		description += " Está aberto."
		if container_items.size() > 0:
			description += " Você pode ver alguns itens dentro."
		else:
			description += " Está vazio."
	else:
		description += " Está fechado, mas não trancado."
	
	GameManager.display_message(description)
	print("Examinando contêiner: ", description)

func add_item_to_container(item_data: Dictionary) -> bool:
	if container_items.size() < max_items:
		container_items.append(item_data)
		print("Item adicionado ao contêiner: ", item_data.get("name", "Item desconhecido"))
		return true
	else:
		print("Contêiner cheio!")
		return false

func lock_container(key_name: String = "") -> void:
	is_locked = true
	required_key = key_name
	update_available_actions()
	print("Contêiner trancado!")

func set_sprites(open_tex: Texture2D, closed_tex: Texture2D) -> void:
	open_sprite = open_tex
	closed_sprite = closed_tex
	update_sprite()

func populate_with_random_items() -> void:
	# Função para popular o contêiner com itens aleatórios
	var possible_items = [
		{"name": "Chave Enferrujada", "description": "Uma chave velha e enferrujada."},
		{"name": "Vela", "description": "Uma vela que pode fornecer luz."},
		{"name": "Fósforos", "description": "Uma caixa de fósforos quase vazia."},
		{"name": "Papel Amassado", "description": "Um papel com escritas ilegíveis."},
		{"name": "Moeda Antiga", "description": "Uma moeda de época desconhecida."}
	]
	
	var num_items = randi() % 3 + 1  # 1 a 3 itens
	for i in range(num_items):
		if container_items.size() < max_items:
			var random_item = possible_items[randi() % possible_items.size()]
			add_item_to_container(random_item)

