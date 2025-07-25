extends CanvasLayer

signal inventory_toggled(is_open: bool)
signal memory_journal_toggled(is_open: bool)

# GameManager e NarrativeManager são autoloads e podem ser acessados diretamente

# UI Elements - usando get_node_or_null para evitar erros
@onready var health_bar: ProgressBar = get_node_or_null("Control/HealthBar")
@onready var sanity_bar: ProgressBar = get_node_or_null("Control/SanityBar")
@onready var hunger_bar: ProgressBar = get_node_or_null("Control/HungerBar")
@onready var fear_bar: ProgressBar = get_node_or_null("Control/FearBar")
@onready var message_display: Label = get_node_or_null("Control/MessageDisplay")

@onready var inventory_panel: Control = get_node_or_null("Ui/InventoryPanel")
@onready var memory_journal_panel: Control = get_node_or_null("Ui/MemoryJournalPanel")
@onready var inventory_grid: GridContainer = get_node_or_null("Ui/InventoryPanel/VBoxContainer/InventoryGrid")
@onready var memory_list: VBoxContainer = get_node_or_null("Ui/MemoryJournalPanel/VBoxContainer/MemoryList")

var is_inventory_open: bool = false
var is_memory_journal_open: bool = false

func _ready() -> void:
	# Verificar se os autoloads existem antes de conectar
	if GameManager:
		# Conectar sinais do GameManager apenas se existirem
		if GameManager.has_signal("sanity_changed"):
			GameManager.sanity_changed.connect(_on_sanity_changed)
		if GameManager.has_signal("hunger_changed"):
			GameManager.hunger_changed.connect(_on_hunger_changed)
		if GameManager.has_signal("fear_changed"):
			GameManager.fear_changed.connect(_on_fear_changed)
	
	# Conectar sinais do NarrativeManager
	if NarrativeManager and NarrativeManager.has_signal("memory_unlocked"):
		NarrativeManager.memory_unlocked.connect(_on_memory_unlocked)
	
	# Configurar UI inicial
	setup_ui()
	update_all_bars()
	
	# Esconder painéis inicialmente se existirem
	if inventory_panel:
		inventory_panel.hide()
	if memory_journal_panel:
		memory_journal_panel.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle_inventory()
	elif event.is_action_pressed("toggle_memory_journal"):
		toggle_memory_journal()
	elif event.is_action_pressed("ui_cancel"):
		close_all_panels()

func setup_ui() -> void:
	# Verificar se GameManager existe e tem as propriedades necessárias
	if not GameManager:
		print("Warning: GameManager not found")
		return
	
	# Configurar barras de status apenas se existirem
	if health_bar:
		if "max_health" in GameManager:
			health_bar.max_value = GameManager.max_health
			health_bar.value = GameManager.current_health
		else:
			health_bar.max_value = 100
			health_bar.value = 100
	
	if sanity_bar:
		if "max_sanity" in GameManager:
			sanity_bar.max_value = GameManager.max_sanity
			sanity_bar.value = GameManager.current_sanity
		else:
			sanity_bar.max_value = 100
			sanity_bar.value = 100
	
	if hunger_bar:
		if "max_hunger" in GameManager:
			hunger_bar.max_value = GameManager.max_hunger
			hunger_bar.value = GameManager.current_hunger
		else:
			hunger_bar.max_value = 100
			hunger_bar.value = 100
	
	if fear_bar:
		if "max_fear" in GameManager:
			fear_bar.max_value = GameManager.max_fear
			fear_bar.value = GameManager.current_fear
		else:
			fear_bar.max_value = 100
			fear_bar.value = 0

func update_all_bars() -> void:
	if not GameManager:
		return
		
	if health_bar:
		if "current_health" in GameManager:
			health_bar.value = GameManager.current_health
		else:
			health_bar.value = 100
			
	if sanity_bar:
		if "current_sanity" in GameManager:
			sanity_bar.value = GameManager.current_sanity
		else:
			sanity_bar.value = 100
			
	if hunger_bar:
		if "current_hunger" in GameManager:
			hunger_bar.value = GameManager.current_hunger
		else:
			hunger_bar.value = 100
			
	if fear_bar:
		if "current_fear" in GameManager:
			fear_bar.value = GameManager.current_fear
		else:
			fear_bar.value = 0

func _on_sanity_changed(new_value: float) -> void:
	if sanity_bar:
		sanity_bar.value = new_value
	
	# Efeitos baseados na sanidade
	if new_value < 30:
		apply_low_sanity_effects()
	elif new_value < 60:
		apply_medium_sanity_effects()
	#else:
		#clear_sanity_effects()

func _on_hunger_changed(new_value: float) -> void:
	if hunger_bar:
		hunger_bar.value = new_value

func _on_fear_changed(new_value: float) -> void:
	if fear_bar:
		fear_bar.value = new_value
	
	# Efeitos visuais baseados no medo
	if new_value > 70:
		apply_high_fear_effects()
	elif new_value > 40:
		apply_medium_fear_effects()
	else:
		clear_fear_effects()

func apply_low_sanity_effects() -> void:
	print("Aplicando efeitos de baixa sanidade")

func apply_medium_sanity_effects() -> void:
	print("Aplicando efeitos médios de sanidade")

#func clear_sanity_effects() -> void:
	#print("Limpando efeitos de sanidade")

func apply_high_fear_effects() -> void:
	print("Aplicando efeitos de alto medo")

func apply_medium_fear_effects() -> void:
	print("Aplicando efeitos médios de medo")

func clear_fear_effects() -> void:
	print("Limpando efeitos de medo")

func toggle_inventory() -> void:
	if not inventory_panel:
		print("Warning: Inventory panel not found")
		return
		
	is_inventory_open = !is_inventory_open
	
	if is_inventory_open:
		show_inventory()
	else:
		hide_inventory()
	
	inventory_toggled.emit(is_inventory_open)

func show_inventory() -> void:
	if inventory_panel:
		inventory_panel.show()
		update_inventory_display()

func hide_inventory() -> void:
	if inventory_panel:
		inventory_panel.hide()

func update_inventory_display() -> void:
	if not inventory_grid:
		print("Warning: Inventory grid not found")
		return
	
	# Limpar grid atual
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Verificar se GameManager tem o método get_inventory
	if not GameManager or not GameManager.has_method("get_inventory"):
		print("Warning: GameManager.get_inventory() not available")
		return
	
	# Adicionar itens do inventário
	var inventory = GameManager.get_inventory()
	for item in inventory:
		var item_button = Button.new()
		item_button.text = item.get("name", "Item")
		item_button.tooltip_text = item.get("description", "Sem descrição")
		inventory_grid.add_child(item_button)

func toggle_memory_journal() -> void:
	if not memory_journal_panel:
		print("Warning: Memory journal panel not found")
		return
		
	is_memory_journal_open = !is_memory_journal_open
	
	if is_memory_journal_open:
		show_memory_journal()
	else:
		hide_memory_journal()
	
	memory_journal_toggled.emit(is_memory_journal_open)

func show_memory_journal() -> void:
	if memory_journal_panel:
		memory_journal_panel.show()
		update_memory_journal_display()

func hide_memory_journal() -> void:
	if memory_journal_panel:
		memory_journal_panel.hide()

func update_memory_journal_display() -> void:
	if not memory_list:
		print("Warning: Memory list not found")
		return
	
	# Limpar lista atual
	for child in memory_list.get_children():
		child.queue_free()
	
	# Verificar se NarrativeManager tem o método necessário
	if not NarrativeManager or not NarrativeManager.has_method("get_discovered_memories"):
		print("Warning: NarrativeManager.get_discovered_memories() not available")
		return
	
	# Adicionar memórias descobertas
	var discovered_memories = NarrativeManager.get_discovered_memories()
	for memory in discovered_memories:
		var memory_container = VBoxContainer.new()
		
		var title_label = Label.new()
		var memory_title = "Título não encontrado"
		if typeof(memory) == TYPE_DICTIONARY and "title" in memory:
			memory_title = memory["title"]
		elif "title" in memory:
			memory_title = memory.title
		
		title_label.text = memory_title
		title_label.add_theme_color_override("font_color", Color.YELLOW)
		memory_container.add_child(title_label)
		
		var text_label = Label.new()
		var memory_description = "Descrição não disponível"
		if typeof(memory) == TYPE_DICTIONARY and "description" in memory:
			memory_description = memory["description"]
		elif "description" in memory:
			memory_description = memory.description
		
		text_label.text = memory_description
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		memory_container.add_child(text_label)
		
		var separator = HSeparator.new()
		memory_container.add_child(separator)
		
		memory_list.add_child(memory_container)

func close_all_panels() -> void:
	if is_inventory_open:
		toggle_inventory()
	if is_memory_journal_open:
		toggle_memory_journal()

func display_message(message: String, duration: float = 3.0) -> void:
	if not message_display:
		print("Warning: Message display not found. Message: " + message)
		return
		
	message_display.text = message
	message_display.show()
	
	# Criar tween para fade out
	var tween = create_tween()
	tween.tween_delay(duration)
	tween.tween_property(message_display, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): message_display.hide())
	tween.tween_callback(func(): message_display.modulate.a = 1.0)

func _on_memory_unlocked(memory_data) -> void:
	var title = "Memória"
	if memory_data:
		if typeof(memory_data) == TYPE_DICTIONARY and "title" in memory_data:
			title = memory_data["title"]
		elif "title" in memory_data:
			title = memory_data.title
	
	display_message("Nova memória desbloqueada: " + title, 4.0)
	
	# Atualizar o journal se estiver aberto
	if is_memory_journal_open:
		update_memory_journal_display()

func show_narrative_state() -> void:
	if not NarrativeManager or not NarrativeManager.has_method("get_narrative_description"):
		print("Warning: NarrativeManager.get_narrative_description() not available")
		return
		
	var state_description = NarrativeManager.get_narrative_description()
	display_message(state_description, 5.0)
