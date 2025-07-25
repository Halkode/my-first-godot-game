# memory_data.gd
extends Resource
class_name MemoryData

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var image_path: String = ""
@export var audio_path: String = ""
@export var associated_item_name: String = "" # Se necessário
@export var triggered_by_action: String = ""  # Se necessário

func _init(memory_id: String = "", memory_title: String = "", memory_text: String = "", item_name: String = "", action: String = "", img_path: String = "", aud_path: String = "") -> void:
	id = memory_id
	title = memory_title
	description = memory_text
	associated_item_name = item_name
	triggered_by_action = action
	image_path = img_path
	audio_path = aud_path
