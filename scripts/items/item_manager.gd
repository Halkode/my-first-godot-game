extends Node

# Tentar encontrar os nós em diferentes locais possíveis
@onready var item_menu: Control = _find_item_menu()
@onready var message_display: Label = _find_message_display()

var current_item_interacting: Node = null

func _ready() -> void:
	print("ItemManager ready - Checking UI nodes...")
	
	if item_menu:
		item_menu.hide()
		print("ItemMenu found at: ", item_menu.get_path())
	else:
		print("Warning: ItemMenu not found - creating temporary menu")
		_create_temporary_menu()
	
	if message_display:
		print("MessageDisplay found at: ", message_display.get_path())
	else:
		print("Warning: MessageDisplay not found")

func _find_item_menu() -> Control:
	# Tentar diferentes caminhos possíveis
	var possible_paths = [
		"ItemMenu",
		"../ItemMenu", 
		"../UIManager/ItemMenu",
		"../ui/ItemMenu",
		"../UI/ItemMenu"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node:
			print("Found ItemMenu at: ", path)
			return node
	
	return null

func _find_message_display() -> Label:
	# Tentar diferentes caminhos possíveis
	var possible_paths = [
		"MessageDisplay",
		"../MessageDisplay",
		"../UIManager/MessageDisplay",
		"../UIManager/HUD/MessageDisplay",
		"../ui/MessageDisplay",
		"../UI/MessageDisplay"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node:
			print("Found MessageDisplay at: ", path)
			return node
	
	return null

func _create_temporary_menu() -> void:
	# Criar um menu temporário se não encontrar
	item_menu = Control.new()
	item_menu.name = "TempItemMenu"
	item_menu.size = Vector2(200, 200)
	
	var panel = Panel.new()
	panel.size = Vector2(200, 200)
	item_menu.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(180, 180)
	panel.add_child(vbox)
	
	# Adicionar à cena principal
	get_tree().current_scene.add_child(item_menu)
	item_menu.hide()
	print("Created temporary ItemMenu")

func show_item_menu(item_node: Node, display_position: Vector2) -> void:
	if not item_menu:
		print("Error: Cannot show item menu - item_menu node not found")
		_create_temporary_menu()
		if not item_menu:
			return

	current_item_interacting = item_node
	print("Showing menu for: ", item_node.name)

	# Verificar se o VBoxContainer existe dentro do item_menu
	var vbox_container = item_menu.get_node_or_null("VBoxContainer")
	if not vbox_container:
		# Tentar encontrar em panel
		var panel = item_menu.get_node_or_null("Panel")
		if panel:
			vbox_container = panel.get_node_or_null("VBoxContainer")
		
		if not vbox_container:
			print("Error: VBoxContainer not found, creating one")
			vbox_container = VBoxContainer.new()
			vbox_container.name = "VBoxContainer"
			item_menu.add_child(vbox_container)

	# Limpa as opções anteriores
	for child in vbox_container.get_children():
		child.queue_free()

	# Aguardar um frame para que os nós sejam removidos
	await get_tree().process_frame

	# Adiciona o título do item
	var item_name_label = Label.new()
	var item_name = get_item_name(item_node)
	item_name_label.text = item_name
	item_name_label.add_theme_color_override("font_color", Color.YELLOW)
	item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_container.add_child(item_name_label)
	
	var separator = HSeparator.new()
	vbox_container.add_child(separator)

	# Adiciona os botões de ação
	var actions_to_display = get_item_actions(item_node)
	for action_text in actions_to_display:
		var button = Button.new()
		button.text = action_text
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.ORANGE)
		button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
		button.add_theme_stylebox_override("hover", hover_style)
		
		button.pressed.connect(Callable(self, "_on_menu_option_selected").bind(action_text, item_node))
		vbox_container.add_child(button)

	# Botão Fechar
	var close_button = Button.new()
	close_button.text = "Fechar"
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.add_theme_color_override("font_color", Color.GRAY)
	close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	close_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var close_hover_style = StyleBoxFlat.new()
	close_hover_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	close_button.add_theme_stylebox_override("hover", close_hover_style)
	close_button.pressed.connect(hide_item_menu)
	vbox_container.add_child(close_button)

	# Posiciona o menu
	position_menu(display_position)
	item_menu.show()
	print("Menu shown successfully")

func position_menu(display_position: Vector2) -> void:
	if not item_menu:
		return
		
	var viewport_rect = get_viewport().get_visible_rect()
	
	# Aguardar um frame para que o menu calcule seu tamanho
	await get_tree().process_frame
	
	var menu_size = item_menu.size
	if menu_size == Vector2.ZERO:
		menu_size = Vector2(200, 150) # Tamanho padrão como fallback
	
	var final_pos = display_position
	# Ajusta para não sair da tela
	final_pos.x = clampf(final_pos.x, 0, viewport_rect.size.x - menu_size.x)
	final_pos.y = clampf(final_pos.y, 0, viewport_rect.size.y - menu_size.y)
	
	item_menu.position = final_pos

func hide_item_menu() -> void:
	if item_menu:
		item_menu.hide()
		current_item_interacting = null
		print("Menu hidden")

func is_menu_visible() -> bool:
	return item_menu and item_menu.visible

func is_click_inside_menu(click_global_pos: Vector2) -> bool:
	if not item_menu or not item_menu.visible:
		return false
	return item_menu.get_global_rect().has_point(click_global_pos)

func _on_menu_option_selected(action: String, item: Node) -> void:
	var item_name = get_item_name(item)
	print("Action selected for ", item_name, ": ", action)
	hide_item_menu()
	
	if item.has_method("handle_action"):
		item.handle_action(action)
	else:
		match action:
			"Pegar":
				_handle_pick_item(item)
			"Examinar":
				_handle_examine_item(item)
			_:
				print("Ação desconhecida: ", action)

func get_item_name(item: Node) -> String:
	if item.has_method("get_item_name"):
		return item.get_item_name()
	elif "item_name" in item:
		return item.item_name
	else:
		return item.name

func get_item_description(item: Node) -> String:
	if item.has_method("get_item_description"):
		return item.get_item_description()
	elif "item_description" in item:
		return item.item_description
	else:
		return "Sem descrição."

func get_item_actions(item: Node) -> Array:
	if item.has_method("get_actions"):
		return item.get_actions()
	elif "actions" in item:
		return item.actions
	else:
		return ["Examinar"]

func _handle_pick_item(item: Node) -> void:
	var item_name = get_item_name(item)
	var item_description = get_item_description(item)
	
	print("Pegou o item: ", item_name)
	var item_data = {"name": item_name, "description": item_description}
	
	if GameManager and GameManager.has_method("add_item_to_inventory"):
		if GameManager.add_item_to_inventory(item_data):
			if item is Area2D or item is RigidBody2D or item is CharacterBody2D:
				item.queue_free()
			display_message(item_name + " foi adicionado ao seu inventário.")
		else:
			display_message("Inventário cheio! Não foi possível adicionar " + item_name + ".")
	else:
		display_message("Pegou: " + item_name)

func _handle_examine_item(item: Node) -> void:
	var item_name = get_item_name(item)
	var item_description = get_item_description(item)
	
	print("Examinando: ", item_name, " - ", item_description)
	display_message(item_name + ": " + item_description)

func display_message(message: String) -> void:
	print("Message: ", message)
	
	if message_display:
		_display_message_with_label(message)
	elif has_node("../UIManager") and get_node("../UIManager").has_method("display_message"):
		get_node("../UIManager").display_message(message)
	else:
		# Criar mensagem temporária na tela
		_create_temporary_message(message)

func _display_message_with_label(message: String) -> void:
	message_display.text = message
	message_display.show()
	
	var tween = create_tween()
	tween.tween_delay(3.0)
	tween.tween_property(message_display, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): message_display.hide())
	tween.tween_callback(func(): message_display.modulate.a = 1.0)

func _create_temporary_message(message: String) -> void:
	var temp_label = Label.new()
	temp_label.text = message
	temp_label.position = Vector2(50, 50)
	temp_label.add_theme_color_override("font_color", Color.WHITE)
	
	get_tree().current_scene.add_child(temp_label)
	
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(temp_label.queue_free)
	get_tree().current_scene.add_child(timer)
	timer.start()
