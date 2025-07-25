class_name Door
extends Item

@export var is_locked: bool = false
@export var required_key: String = ""
@export var is_open: bool = false
@export var open_sprite: Texture2D
@export var closed_sprite: Texture2D

signal door_opened
signal door_closed
signal door_locked
signal door_unlocked

func _ready() -> void:
	super._ready()
	
	# Configurar propriedades específicas da porta
	item_name = "Porta"
	item_description = "Uma porta de madeira velha."
	
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
			open_door()
		"Fechar":
			close_door()
		"Destrancar":
			unlock_door()
		"Tentar abrir":
			try_open_locked_door()
		"Examinar":
			examine_door()

func open_door() -> void:
	if is_locked:
		GameManager.display_message("A porta está trancada.")
		return
	
	if is_open:
		GameManager.display_message("A porta já está aberta.")
		return
	
	is_open = true
	update_sprite()
	update_available_actions()
	door_opened.emit()
	GameManager.display_message("Você abriu a porta.")
	print("Porta aberta!")

func close_door() -> void:
	if not is_open:
		GameManager.display_message("A porta já está fechada.")
		return
	
	is_open = false
	update_sprite()
	update_available_actions()
	door_closed.emit()
	GameManager.display_message("Você fechou a porta.")
	print("Porta fechada!")

func unlock_door() -> void:
	if not is_locked:
		GameManager.display_message("A porta não está trancada.")
		return
	
	if required_key == "" or GameManager.has_item(required_key):
		is_locked = false
		update_available_actions()
		door_unlocked.emit()
		GameManager.display_message("Você destrancou a porta.")
		
		# Remover a chave do inventário se necessário
		if required_key != "":
			GameManager.remove_item_from_inventory(required_key)
		
		print("Porta destrancada!")
	else:
		GameManager.display_message("Você precisa de uma chave para destrancar esta porta.")

func try_open_locked_door() -> void:
	GameManager.display_message("A porta está trancada. Você precisa de uma chave.")
	GameManager.increase_fear(5)  # Frustração aumenta o medo
	print("Tentativa de abrir porta trancada!")

func examine_door() -> void:
	var description = item_description
	
	if is_locked:
		description += " Está trancada."
		if required_key != "":
			description += " Parece precisar de uma chave específica."
	elif is_open:
		description += " Está aberta."
	else:
		description += " Está fechada, mas não trancada."
	
	GameManager.display_message(description)
	print("Examinando porta: ", description)

func lock_door(key_name: String = "") -> void:
	is_locked = true
	required_key = key_name
	update_available_actions()
	door_locked.emit()
	print("Porta trancada!")

func set_sprites(open_tex: Texture2D, closed_tex: Texture2D) -> void:
	open_sprite = open_tex
	closed_sprite = closed_tex
	update_sprite()

