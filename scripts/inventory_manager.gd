extends Node

signal inventory_updated

var inventory_items: Array[Dictionary] = []
@export var max_slots: int = 12

func _ready() -> void:
	# Certificar-se de que o GameManager está disponível
	if not GameManager:
		print("ERRO: GameManager não encontrado. Certifique-se de que está configurado como autoload.")
		return
	
	# Carregar inventário do GameManager se existir
	if GameManager.inventory.size() > 0:
		inventory_items = GameManager.inventory.duplicate()
		print("Inventário carregado do GameManager.")

func add_item(item_data: Dictionary) -> bool:
	if inventory_items.size() < max_slots:
		inventory_items.append(item_data)
		GameManager.add_item_to_inventory(item_data) # Sincroniza com GameManager
		inventory_updated.emit()
		print("Item adicionado ao inventário: ", item_data.get("name", "Item desconhecido"))
		return true
	else:
		print("Inventário cheio! Não foi possível adicionar ", item_data.get("name", "Item desconhecido"))
		GameManager.display_message("Inventário cheio!") # Exibe mensagem via GameManager
		return false

func remove_item(item_name: String) -> bool:
	for i in range(inventory_items.size()):
		if inventory_items[i].get("name") == item_name:
			inventory_items.remove_at(i)
			GameManager.remove_item_from_inventory(item_name) # Sincroniza com GameManager
			inventory_updated.emit()
			print("Item removido do inventário: ", item_name)
			return true
	print("Item não encontrado no inventário: ", item_name)
	return false

func has_item(item_name: String) -> bool:
	for item in inventory_items:
		if item.get("name") == item_name:
			return true
	return false

func get_items() -> Array[Dictionary]:
	return inventory_items.duplicate()

func get_item_count(item_name: String) -> int:
	var count = 0
	for item in inventory_items:
		if item.get("name") == item_name:
			count += 1
	return count
