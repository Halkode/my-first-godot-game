# ItemManager.gd
extends Node

# Usando get_node_or_null para evitar erros quando os nós não existem
@onready var item_menu: Control = get_node_or_null("ItemMenu")
@onready var message_display: Label = get_node_or_null("MessageDisplay")

var current_item_interacting: Node = null # O item que está atualmente com o menu aberto

func _ready() -> void:
	# Verificar se o item_menu existe antes de tentar escondê-lo
	if item_menu:
		item_menu.hide()
	else:
		print("Warning: ItemMenu node not found at ../UIManager/ItemMenu")
	
	# Verificar se message_display existe
	if not message_display:
		print("Warning: MessageDisplay node not found at ../UIManager/HUD/MessageDisplay")

func show_item_menu(item_node: Node, display_position: Vector2) -> void:
	if not item_menu:
		print("Error: Cannot show item menu - item_menu node not found")
		return

	current_item_interacting = item_node

	# Verificar se o VBoxContainer existe dentro do item_menu
	var vbox_container = item_menu.get_node_or_null("VBoxContainer")
	if not vbox_container:
		print("Error: VBoxContainer not found inside ItemMenu")
		return

	# Limpa as opções anteriores
	for child in vbox_container.get_children():
		child.queue_free()

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

func is_menu_visible() -> bool:
	return item_menu and item_menu.visible

func is_click_inside_menu(click_global_pos: Vector2) -> bool:
	if not item_menu or not item_menu.visible:
		return false
	return item_menu.get_global_rect().has_point(click_global_pos)

func _on_menu_option_selected(action: String, item: Node) -> void:
	var item_name = get_item_name(item)
	print("Action selected for ", item_name, ": ", action)
	hide_item_menu() # Esconde o menu após a seleção
	
	# Delega a ação para o próprio item, se ele tiver o método handle_action
	if item.has_method("handle_action"):
		item.handle_action(action)
	else:
		# Fallback para ações genéricas se o item não tiver um handler específico
		match action:
			"Pegar":
				_handle_pick_item(item)
			"Examinar":
				_handle_examine_item(item)
			_:
				print("Ação desconhecida ou não tratada pelo item: ", action)

# --- Helpers para obter informações do item de forma segura ---
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
		return ["Examinar"] # Fallback padrão

# --- Handlers de Ação Genéricos (para itens que não têm handle_action) ---
func _handle_pick_item(item: Node) -> void:
	var item_name = get_item_name(item)
	var item_description = get_item_description(item)
	
	print("Pegou o item: ", item_name)
	var item_data = {"name": item_name, "description": item_description}
	
	# Verificar se GameManager existe e tem o método necessário
	if not GameManager:
		print("Error: GameManager not found")
		display_message("Erro: Sistema de inventário não disponível.")
		return
	
	if not GameManager.has_method("add_item_to_inventory"):
		print("Error: GameManager.add_item_to_inventory() method not found")
		display_message("Erro: Método de adicionar item não encontrado.")
		return
	
	if GameManager.add_item_to_inventory(item_data):
		if item is Area2D or item is RigidBody2D or item is CharacterBody2D:
			item.queue_free() # Remove o item do mundo
		display_message(item_name + " foi adicionado ao seu inventário.")
	else:
		display_message("Inventário cheio! Não foi possível adicionar " + item_name + ".")

func _handle_examine_item(item: Node) -> void:
	var item_name = get_item_name(item)
	var item_description = get_item_description(item)
	
	print("Examinando: ", item_name, " - ", item_description)
	display_message(item_name + ": " + item_description)

# Função para exibir mensagens temporárias na tela (usando UIManager)
func display_message(message: String) -> void:
	# Primeiro tentar usar o message_display do UIManager
	if message_display:
		_display_message_with_label(message)
	# Se não existir, tentar usar o UIManager diretamente
	elif has_node("../UIManager") and get_node("../UIManager").has_method("display_message"):
		get_node("../UIManager").display_message(message)
	# Como último recurso, apenas imprimir no console
	else:
		print("Message: ", message)

func _display_message_with_label(message: String) -> void:
	message_display.text = message
	message_display.show()
	
	# Criar tween para fade out
	var tween = create_tween()
	tween.tween_delay(3.0) # Duração da mensagem
	tween.tween_property(message_display, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): message_display.hide())
	tween.tween_callback(func(): message_display.modulate.a = 1.0)
