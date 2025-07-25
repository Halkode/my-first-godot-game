extends Item

@export var memory_id: String = ""
@export var memory_title: String = ""
@export var memory_description: String = ""
@export var memory_image_path: String = ""
@export var memory_audio_path: String = ""
@export var memory_discovered: bool = false
@export var trigger_on_examine: bool = true
@export var trigger_on_interact: bool = false
@export var one_time_only: bool = true

signal memory_triggered(memory_data: MemoryData)

@onready var narrative_manager: NarrativeManager = get_node("/root/NarrativeManager")

func _ready() -> void:
	super._ready()
	
	# Configurar propriedades específicas do trigger de memória
	item_name = "Objeto Misterioso"
	item_description = "Algo sobre este objeto parece familiar..."
	
	# Configurar ações disponíveis
	actions = ["Examinar"]
	if trigger_on_interact:
		actions.append("Tocar")

func handle_action(action: String) -> void:
	match action:
		"Examinar":
			examine_memory_object()
		"Tocar":
			if trigger_on_interact:
				trigger_memory()
		_:
			super.handle_action(action) # Chama o handler genérico do Item

func examine_memory_object() -> void:
	if trigger_on_examine and not memory_discovered:
		trigger_memory()
	else:
		GameManager.display_message(item_description)

func trigger_memory() -> void:
	if memory_discovered and one_time_only:
		GameManager.display_message("Você já se lembra deste objeto.")
		return
	
	if memory_id == "":
		print("ERRO: MemoryTrigger não configurado corretamente: memory_id está vazio!")
		return
	
	if narrative_manager:
		var memory_data_to_discover = MemoryData.new(
			memory_id,
			memory_title if memory_title != "" else "Memória Desconhecida",
			memory_description if memory_description != "" else item_description,
			memory_image_path,
			memory_audio_path
		)
		
		var success = narrative_manager.unlock_memory(memory_id) # narrative_manager.discover_memory foi renomeado para unlock_memory
		if success:
			memory_discovered = true
			memory_triggered.emit(memory_data_to_discover)
			GameManager.display_message("MEMÓRIA DESBLOQUEADA: " + memory_data_to_discover.title)
			create_memory_visual_effect()
			print("Memória ativada: ", memory_id)
		else:
			GameManager.display_message("Você já se lembra deste objeto.")
	else:
		print("ERRO: NarrativeManager não encontrado para o MemoryTrigger.")

func create_memory_visual_effect() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.2)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.2)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func set_memory_data(id: String, title: String, description: String, image_path: String = "", audio_path: String = "") -> void:
	memory_id = id
	memory_title = title
	memory_description = description
	memory_image_path = image_path
	memory_audio_path = audio_path

func reset_memory() -> void:
	memory_discovered = false
