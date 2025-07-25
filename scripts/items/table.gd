class_name Table
extends Item

var interaction_menu: Control
var menu_options: Array[String] = [
	"Examinar Mesa",
	"Pegar Objeto",
	"Usar Mesa",
	"Cancelar"
]

func _ready() -> void:
	super._ready()
	item_name = "Mesa"
	create_interaction_menu()

func create_interaction_menu() -> void:
	# Criar menu de interação
	interaction_menu = Control.new()
	interaction_menu.name = "InteractionMenu"
	
	# Panel de fundo
	var panel = Panel.new()
	panel.size = Vector2(200, 150)
	panel.position = Vector2(-100, -200)  # Posicionar acima do item
	interaction_menu.add_child(panel)
	
	# Container vertical para os botões
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(180, 130)
	panel.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = item_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Criar botões para cada opção
	for i in range(menu_options.size()):
		var button = Button.new()
		button.text = menu_options[i]
		button.custom_minimum_size = Vector2(160, 25)
		button.pressed.connect(_on_menu_option_selected.bind(i))
		vbox.add_child(button)
	
	# Adicionar à cena mas manter invisível
	add_child(interaction_menu)
	interaction_menu.visible = false

func interact(player: Node2D) -> void:
	show_interaction_menu(player)

func show_interaction_menu(player: Node2D) -> void:
	if not interaction_menu:
		create_interaction_menu()
	
	interaction_menu.visible = true
	print("Showing interaction menu for ", item_name)
	
	# Pausar o jogo ou impedir outras interações
	get_tree().paused = true

func _on_menu_option_selected(option_index: int) -> void:
	hide_interaction_menu()
	
	match option_index:
		0:  # Examinar Mesa
			examine_table()
		1:  # Pegar Objeto
			take_object()
		2:  # Usar Mesa
			use_table()
		3:  # Cancelar
			print("Interação cancelada")

func hide_interaction_menu() -> void:
	if interaction_menu:
		interaction_menu.visible = false
	get_tree().paused = false

func examine_table() -> void:
	print("Você examina a mesa. É uma mesa de madeira robusta.")
	show_message("É uma mesa de madeira bem conservada. Há alguns objetos sobre ela.")

func take_object() -> void:
	print("Você pega um objeto da mesa")
	show_message("Você pegou uma chave antiga da mesa!")

func use_table() -> void:
	print("Você usa a mesa")
	show_message("Você se senta à mesa e descansa um pouco.")

func show_message(text: String) -> void:
	# Criar uma mensagem temporária
	var message_label = Label.new()
	message_label.text = text
	message_label.position = Vector2(-100, -250)
	message_label.size = Vector2(200, 50)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Adicionar fundo
	var message_panel = Panel.new()
	message_panel.position = Vector2(-100, -250)
	message_panel.size = Vector2(200, 50)
	message_panel.add_child(message_label)
	
	add_child(message_panel)
	
	# Remover após 3 segundos
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(message_panel.queue_free)
	add_child(timer)
	timer.start()
