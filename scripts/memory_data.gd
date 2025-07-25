class_name MemoryData
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var text: String = ""
@export var associated_item_name: String = "" # Item que pode disparar a memória
@export var triggered_by_action: String = "" # Ação no item que dispara (Examinar, Tocar, etc.)

func _init(memory_id: String = "", memory_title: String = "", memory_text: String = "", item_name: String = "", action: String = "") -> void:
	id = memory_id
	title = memory_title
	text = memory_text
	associated_item_name = item_name
	triggered_by_action = action


