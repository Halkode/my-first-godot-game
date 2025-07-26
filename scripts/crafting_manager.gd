extends Node

@export var recipes: Array[Resource] # Array de recursos de receita

var game_manager := GameManager

func _ready() -> void:
	if not game_manager:
		print("ERRO: GameManager não encontrado para o CraftingManager.")

func craft_item(recipe_name: String) -> bool:
	var recipe_to_craft = get_recipe_by_name(recipe_name)
	if not recipe_to_craft:
		game_manager.display_message("Receita não encontrada: " + recipe_name)
		return false

	# Verificar se o jogador tem todos os ingredientes
	for ingredient in recipe_to_craft.ingredients:
		if not game_manager.has_item(ingredient.item_name) or game_manager.get_item_count(ingredient.item_name) < ingredient.quantity:
			game_manager.display_message("Faltam ingredientes para " + recipe_name + ".")
			return false

	# Remover ingredientes do inventário
	for ingredient in recipe_to_craft.ingredients:
		for i in range(ingredient.quantity):
			game_manager.remove_item_from_inventory(ingredient.item_name)

	# Adicionar item craftado ao inventário
	var crafted_item_data = {"name": recipe_to_craft.crafted_item_name, "description": recipe_to_craft.crafted_item_description}
	if game_manager.add_item_to_inventory(crafted_item_data):
		game_manager.display_message("Você craftou: " + recipe_to_craft.crafted_item_name + "!")
		game_manager.modify_sanity(5)
		return true
	else:
		game_manager.display_message("Seu inventário está cheio! Não foi possível adicionar o item craftado.")
		return false

func get_recipe_by_name(recipe_name: String) -> Resource:
	for recipe in recipes:
		if recipe is Recipe and recipe.recipe_name == recipe_name:
			return recipe
	return null

func get_craftable_recipes() -> Array[Resource]:
	var craftable_list: Array[Resource] = []
	for recipe in recipes:
		if can_craft(recipe):
			craftable_list.append(recipe)
	return craftable_list

func can_craft(recipe: Resource) -> bool:
	if not (recipe is Recipe): return false
	
	for ingredient in recipe.ingredients:
		if not game_manager.has_item(ingredient.item_name) or game_manager.get_item_count(ingredient.item_name) < ingredient.quantity:
			return false
	return true

func add_recipe(recipe_resource: Resource) -> void:
	if recipe_resource is Recipe and not recipes.has(recipe_resource):
		recipes.append(recipe_resource)
		print("Receita adicionada: ", recipe_resource.recipe_name)

func remove_recipe(recipe_name: String) -> void:
	var recipe_to_remove = get_recipe_by_name(recipe_name)
	if recipe_to_remove:
		recipes.erase(recipe_to_remove)
		print("Receita removida: ", recipe_name)
