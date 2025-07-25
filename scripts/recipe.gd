class_name Recipe
extends Resource

@export var recipe_name: String = ""
@export var crafted_item_name: String = ""
@export var crafted_item_description: String = ""
@export var ingredients: Array[Ingredient] = []
@export var crafting_time: float = 2.0 # Tempo em segundos para craftar
@export var required_tool: String = "" # Ferramenta necessária (opcional)

func _init(name: String = "", item_name: String = "", item_desc: String = "", ingredient_list: Array[Ingredient] = [], time: float = 2.0, tool: String = "") -> void:
	recipe_name = name
	crafted_item_name = item_name
	crafted_item_description = item_desc
	ingredients = ingredient_list
	crafting_time = time
	required_tool = tool

func get_ingredient_names() -> Array[String]:
	var names: Array[String] = []
	for ingredient in ingredients:
		names.append(ingredient.item_name)
	return names

func get_total_ingredients() -> int:
	var total = 0
	for ingredient in ingredients:
		total += ingredient.quantity
	return total

func has_ingredient(item_name: String) -> bool:
	for ingredient in ingredients:
		if ingredient.item_name == item_name:
			return true
	return false

func get_ingredient_quantity(item_name: String) -> int:
	for ingredient in ingredients:
		if ingredient.item_name == item_name:
			return ingredient.quantity
	return 0

