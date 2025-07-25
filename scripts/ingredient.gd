class_name Ingredient
extends Resource

@export var item_name: String = ""
@export var quantity: int = 1

func _init(name: String = "", qty: int = 1) -> void:
	item_name = name
	quantity = qty

