# ItemManager.gd
extends Node2D

@onready var item_menu: Control = $"ItemMenu" # Caminho para o seu menu de UI
@onready var message_label_container: CanvasLayer = $"MessageLabelContainer" # Para mensagens temporárias

var current_item_interacting: Node = null # O item que está atualmente com o menu aberto

func _ready() -> void:
	if item_menu:
		item_menu.hide() # Esconde o menu no início
	
	if message_label_container:
		message_label_container.hide() # Esconde o container de mensagens no início

	# Conectar o sinal de todos os InteractiveItems na cena ao Player
	# Isso é mais robusto do que o Player se conectar diretamente.
	# Assumimos que todos os InteractiveItems são filhos de um nó "Items" ou estão na cena principal.
	# Você pode precisar ajustar isso dependendo de como você organiza seus itens.
	for child in get_tree().get_nodes_in_group("interactive_items"): # Adicione seus InteractiveItems a um grupo "interactive_items"
		if child is Area2D and child.has_signal("item_clicked"):
			child.item_clicked.connect(Callable(get_node("/root/main/TileMaps/Player"), "on_item_clicked"))
			print("Connected item: ", child.name)


func show_item_menu(item_node: Node, display_position: Vector2) -> void:
	if not item_menu: return

	current_item_interacting = item_node

	# Limpa as opções anteriores
	for child in item_menu.get_node("VBoxContainer").get_children():
		child.queue_free()

	# Adiciona o título do item
	var item_name_label = Label.new()
	item_name_label.text = item_node.item_name if item_node.has_method("item_name") else item_node.name
	item_name_label.add_theme_color_override("font_color", Color.YELLOW)
	item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_menu.get_node("VBoxContainer").add_child(item_name_label)
	
	var separator = HSeparator.new()
	item_menu.get_node("VBoxContainer").add_child(separator)

	# Adiciona os botões de ação
	var actions_to_display = item_node.actions if item_node.has_method("actions") else ["Examinar"] # Fallback
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
		item_menu.get_node("VBoxContainer").add_child(button)

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
	item_menu.get_node("VBoxContainer").add_child(close_button)

	# Posiciona o menu
	var viewport_rect = get_viewport_rect()
	var menu_size = item_menu.get_minimum_size() # Obtém o tamanho mínimo para posicionar
	
	var final_pos = display_position
	# Ajusta para não sair da tela
	final_pos.x = clampi(final_pos.x, 0, viewport_rect.size.x - menu_size.x)
	final_pos.y = clampi(final_pos.y, 0, viewport_rect.size.y - menu_size.y)
	
	item_menu.position = final_pos
	item_menu.show()


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
	print("Action selected for ", item.item_name if item.has_method("item_name") else item.name, ": ", action)
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

# --- Handlers de Ação Genéricos (para itens que não têm handle_action) ---
func _handle_pick_item(item: Node) -> void:
	print("Pegou o item: ", item.item_name if item.has_method("item_name") else item.name)
	var item_data = {"name": item.item_name if item.has_method("item_name") else item.name, "description": item.item_description if item.has_method("item_description") else "Sem descrição."}
	if GameManager.add_item_to_inventory(item_data):
		if item is Area2D: # Se for um nó de cena, pode ser removido
			item.queue_free() # Remove o item do mundo
		display_message(item.item_name + " foi adicionado ao seu inventário.")
	else:
		display_message("Inventário cheio! Não foi possível adicionar " + item.item_name + ".")

func _handle_examine_item(item: Node) -> void:
	print("Examinando: ", item.item_name if item.has_method("item_name") else item.name, " - ", item.item_description if item.has_method("item_description") else "Sem descrição.")
	display_message(item.item_name + ": " + (item.item_description if item.has_method("item_description") else "Sem descrição."))

# Função para exibir mensagens temporárias na tela
func display_message(message: String) -> void:
	if not message_label_container: return

	# Limpa mensagens anteriores
	for child in message_label_container.get_children():
		child.queue_free()

	var message_label = Label.new()
	message_label.text = message
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	message_label.add_theme_constant_override("shadow_offset_x", 1)
	message_label.add_theme_constant_override("shadow_offset_y", 1)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE) # Centraliza no topo

	message_label_container.add_child(message_label)
	message_label_container.show()

	# Ajusta a posição após adicionar para que o tamanho mínimo seja calculado
	message_label.position.x = (get_viewport_rect().size.x / 2) - (message_label.get_minimum_size().x / 2)
	message_label.position.y = 50 # Posição vertical

	var tween = create_tween()
	tween.tween_property(message_label, "modulate", Color(1, 1, 1, 0), 0.0) # Começa invisível
	tween.tween_property(message_label, "modulate", Color(1, 1, 1, 1), 0.5) # Fade in
	tween.tween_interval(2.0) # Espera 2 segundos
	tween.tween_property(message_label, "modulate", Color(1, 1, 1, 0), 0.5) # Fade out
	tween.tween_callback(Callable(message_label, "queue_free")) # Remove a label
	tween.tween_callback(Callable(message_label_container, "hide")) # Esconde o container


