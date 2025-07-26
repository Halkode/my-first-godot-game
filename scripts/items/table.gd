extends Area2D  # Mudei para Area2D para facilitar detecção

var item_name: String = "Mesa"
var item_description: String = "Uma mesa de madeira robusta com alguns objetos sobre ela."
var actions: Array[String] = ["Examinar", "Pegar Objeto", "Usar Mesa"]
var interaction_range_tiles: int = 1  # Range de interação em tiles

func _ready() -> void:
	# Certificar que está no grupo correto
	add_to_group("items")
	
	# Conectar sinal de input se necessário (backup)
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)

# Método principal chamado pelo Player
func interact(player: Node2D) -> void:
	print("Table interact called by player")
	if ItemManager:
		ItemManager.show_item_menu(self, global_position)
	else:
		print("ItemManager não encontrado!")

# Backup: sinal direto do Area2D (caso o Player não detecte)
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Table clicked directly via Area2D signal")
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("on_item_clicked"):
			player.on_item_clicked(self)

# Métodos para o ItemManager obter informações
func get_item_name() -> String:
	return item_name

func get_item_description() -> String:
	return item_description

func get_actions() -> Array:
	return actions

# Método para lidar com as ações selecionadas no menu
func handle_action(action: String) -> void:
	print("Table handling action: ", action)
	match action:
		"Examinar":
			examine_table()
		"Pegar Objeto":
			take_object()
		"Usar Mesa":
			use_table()
		_:
			print("Ação não reconhecida: ", action)

func examine_table() -> void:
	print("Você examina a mesa. É uma mesa de madeira robusta.")
	if ItemManager:
		ItemManager.display_message("É uma mesa de madeira bem conservada. Há alguns objetos sobre ela.")

func take_object() -> void:
	print("Você pega um objeto da mesa")
	
	# Criar dados do item para o inventário
	var item_data = {
		"name": "Chave Antiga",
		"description": "Uma chave enferrujada que parece muito antiga. Para que será?"
	}
	
	# Verificar se GameManager existe e adicionar ao inventário
	if GameManager and GameManager.has_method("add_item_to_inventory"):
		if GameManager.add_item_to_inventory(item_data):
			if ItemManager:
				ItemManager.display_message("Você pegou uma chave antiga da mesa!")
			# Remover esta ação das opções disponíveis
			if "Pegar Objeto" in actions:
				actions.erase("Pegar Objeto")
		else:
			if ItemManager:
				ItemManager.display_message("Inventário cheio! Não foi possível pegar o objeto.")
	else:
		if ItemManager:
			ItemManager.display_message("Você pegou uma chave antiga da mesa!")
		# Mesmo sem GameManager, remover a ação
		if "Pegar Objeto" in actions:
			actions.erase("Pegar Objeto")

func use_table() -> void:
	print("Você usa a mesa")
	if ItemManager:
		ItemManager.display_message("Você se senta à mesa e descansa um pouco. Sua sanidade aumenta ligeiramente.")
	
	# Restaurar sanidade se GameManager existir
	if GameManager and GameManager.has_method("modify_sanity"):
		GameManager.modify_sanity(5)
