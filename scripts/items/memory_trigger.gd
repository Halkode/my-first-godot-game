class_name MemoryTrigger
extends Item

@export var memory_id: String = ""
@export var memory_text: String = ""
@export var memory_discovered: bool = false
@export var trigger_on_examine: bool = true
@export var trigger_on_interact: bool = false
@export var one_time_only: bool = true

signal memory_triggered(memory_id: String, memory_text: String)

@onready var narrative_manager: NarrativeManager = get_node("/root/main/NarrativeManager")

func _ready() -> void:
	super._ready()
	
	# Configurar propriedades específicas do trigger de memória
	item_name = "Objeto Misterioso"
	item_description = "Algo sobre este objeto parece familiar..."
	
	# Configurar ações disponíveis
	actions = ["Examinar"]
	if trigger_on_interact:
		actions.append("Tocar")

func interact(player: Node2D) -> void:
	if trigger_on_interact and not memory_discovered:
		trigger_memory()
	super.interact(player)

func handle_action(action: String) -> void:
	match action:
		"Examinar":
			examine_memory_object()
		"Tocar":
			if trigger_on_interact:
				trigger_memory()

func examine_memory_object() -> void:
	if trigger_on_examine and not memory_discovered:
		trigger_memory()
	else:
		GameManager.display_message(item_description)

func trigger_memory() -> void:
	if memory_discovered and one_time_only:
		GameManager.display_message("Você já se lembra deste objeto.")
		return
	
	if memory_id == "" or memory_text == "":
		print("ERRO: MemoryTrigger não configurado corretamente!")
		return
	
	if narrative_manager:
		var success = narrative_manager.discover_memory(memory_id)
		if success:
			memory_discovered = true
			memory_triggered.emit(memory_id, memory_text)
			GameManager.display_message("MEMÓRIA: " + memory_text)
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

func set_memory_data(id: String, text: String) -> void:
	memory_id = id
	memory_text = text

func reset_memory() -> void:
	memory_discovered = false


