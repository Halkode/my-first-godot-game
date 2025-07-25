extends CanvasLayer

signal inventory_toggled(is_open: bool)
signal memory_journal_toggled(is_open: bool)

# GameManager e NarrativeManager são autoloads e podem ser acessados diretamente

# UI Elements
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var sanity_bar: ProgressBar = $HUD/SanityBar
@onready var hunger_bar: ProgressBar = $HUD/HungerBar
@onready var fear_bar: ProgressBar = $HUD/FearBar

@onready var inventory_panel: Control = $InventoryPanel
@onready var memory_journal_panel: Control = $MemoryJournalPanel
@onready var message_display: Label = $HUD/MessageDisplay

@onready var inventory_grid: GridContainer = $InventoryPanel/VBoxContainer/InventoryGrid
@onready var memory_list: VBoxContainer = $MemoryJournalPanel/VBoxContainer/MemoryList

var is_inventory_open: bool = false
var is_memory_journal_open: bool = false

func _ready() -> void:
	# Conectar sinais do GameManager
	GameManager.sanity_changed.connect(_on_sanity_changed)
	GameManager.hunger_changed.connect(_on_hunger_changed)
	GameManager.fear_changed.connect(_on_fear_changed)
	
	# Conectar sinais do NarrativeManager
	NarrativeManager.memory_unlocked.connect(_on_memory_unlocked)
	
	# Configurar UI inicial
	setup_ui()
	update_all_bars()
	
	# Esconder painéis inicialmente
	inventory_panel.hide()
	memory_journal_panel.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle_inventory()
	elif event.is_action_pressed("toggle_memory_journal"):
		toggle_memory_journal()
	elif event.is_action_pressed("ui_cancel"):
		close_all_panels()

func setup_ui() -> void:
	# Configurar barras de status
	if health_bar:
		health_bar.max_value = GameManager.max_health
		health_bar.value = GameManager.current_health
	
	if sanity_bar:
		sanity_bar.max_value = GameManager.max_sanity
		sanity_bar.value = GameManager.current_sanity
	
	if hunger_bar:
		hunger_bar.max_value = GameManager.max_hunger
		hunger_bar.value = GameManager.current_hunger
	
	if fear_bar:
		fear_bar.max_value = GameManager.max_fear
		fear_bar.value = GameManager.current_fear

func update_all_bars() -> void:
	if health_bar:
		health_bar.value = GameManager.current_health
	if sanity_bar:
		sanity_bar.value = GameManager.current_sanity
	if hunger_bar:
		hunger_bar.value = GameManager.current_hunger
	if fear_bar:
		fear_bar.value = GameManager.current_fear

func _on_sanity_changed(new_value: float) -> void:
	if sanity_bar:
		sanity_bar.value = new_value
	
	# Efeitos baseados na sanidade
	if new_value < 30:
		# Efeito de tela tremendo ou distorcida
		apply_low_sanity_effects()
	elif new_value < 60:
		# Efeitos visuais leves
		apply_medium_sanity_effects()
	else:
		clear_sanity_effects()

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
	# Implementar efeitos visuais para baixa sanidade
	# Exemplo: tela tremendo, cores distorcidas, etc.
	print("Aplicando efeitos de baixa sanidade")

func apply_medium_sanity_effects() -> void:
	# Efeitos visuais médios
	print("Aplicando efeitos médios de sanidade")

func clear_sanity_effects() -> void:
	# Limpar efeitos visuais
	print("Limpando efeitos de sanidade")

func apply_high_fear_effects() -> void:
	# Efeitos visuais para alto medo
	print("Aplicando efeitos de alto medo")

func apply_medium_fear_effects() -> void:
	# Efeitos visuais médios de medo
	print("Aplicando efeitos médios de medo")

func clear_fear_effects() -> void:
	# Limpar efeitos de medo
	print("Limpando efeitos de medo")

func toggle_inventory() -> void:
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
		return
	
	# Limpar grid atual
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Adicionar itens do inventário
	var inventory = GameManager.get_inventory()
	for item in inventory:
		var item_button = Button.new()
		item_button.text = item.get("name", "Item")
		item_button.tooltip_text = item.get("description", "Sem descrição")
		inventory_grid.add_child(item_button)

func toggle_memory_journal() -> void:
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
		return
	
	# Limpar lista atual
	for child in memory_list.get_children():
		child.queue_free()
	
	# Adicionar memórias descobertas
	var discovered_memories = NarrativeManager.get_discovered_memories()
	for memory in discovered_memories:
		var memory_container = VBoxContainer.new()
		
		var title_label = Label.new()
		title_label.text = memory.title
		title_label.add_theme_color_override("font_color", Color.YELLOW)
		memory_container.add_child(title_label)
		
		var text_label = Label.new()
		text_label.text = memory.description # Alterado de memory.text para memory.description
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
	if message_display:
		message_display.text = message
		message_display.show()
		
		# Criar tween para fade out
		var tween = create_tween()
		tween.tween_delay(duration)
		tween.tween_property(message_display, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): message_display.hide())
		tween.tween_callback(func(): message_display.modulate.a = 1.0)

func _on_memory_unlocked(memory_data: MemoryData) -> void:
	display_message("Nova memória desbloqueada: " + memory_data.title, 4.0)
	
	# Atualizar o journal se estiver aberto
	if is_memory_journal_open:
		update_memory_journal_display()

func show_narrative_state() -> void:
	var state_description = NarrativeManager.get_narrative_description()
	display_message(state_description, 5.0)
