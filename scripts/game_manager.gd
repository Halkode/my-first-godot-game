class_name GameManager
extends Node

# Singleton para gerenciar estado global do jogo
signal sanity_changed(new_value: float)
signal hunger_changed(new_value: float)
signal fear_changed(new_value: float)
signal memory_discovered(memory_id: String)
signal day_started
signal night_started

# Estados do jogador
@export var max_sanity: float = 100.0
@export var max_hunger: float = 100.0
@export var max_fear: float = 100.0

var current_sanity: float = 100.0
var current_hunger: float = 50.0
var current_fear: float = 20.0

# Sistema de memórias
var discovered_memories: Array[String] = []
var total_memories: int = 10

# Sistema de inventário
var inventory: Array[Dictionary] = []
var max_inventory_slots: int = 12

# Estado do jogo
var game_time: float = 0.0
var is_night: bool = false
var current_scene: String = "basement"

func _ready() -> void:
	# Configurar como singleton se necessário
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conectar sinais do DayNightCycle
	var day_night_cycle = get_node_or_null("/root/main/DayNightCycle")
	if day_night_cycle:
		day_night_cycle.day_started.connect(_on_day_started)
		day_night_cycle.night_started.connect(_on_night_started)

func _process(delta: float) -> void:
	# Atualizar tempo de jogo
	game_time += delta
	
	# Degradação gradual da sanidade e aumento da fome
	if current_sanity > 0:
		current_sanity -= delta * 0.5  # Perde sanidade lentamente
		current_sanity = max(0, current_sanity)
		sanity_changed.emit(current_sanity)
	
	if current_hunger < max_hunger:
		current_hunger += delta * 0.3  # Fome aumenta lentamente
		current_hunger = min(max_hunger, current_hunger)
		hunger_changed.emit(current_hunger)

# Funções de sanidade
func modify_sanity(amount: float) -> void:
	current_sanity = clamp(current_sanity + amount, 0, max_sanity)
	sanity_changed.emit(current_sanity)
	
	# Efeitos baseados na sanidade
	if current_sanity < 30:
		increase_fear(10)
	elif current_sanity < 60:
		increase_fear(5)

func get_sanity_percentage() -> float:
	return current_sanity / max_sanity

# Funções de fome
func modify_hunger(amount: float) -> void:
	current_hunger = clamp(current_hunger + amount, 0, max_hunger)
	hunger_changed.emit(current_hunger)
	
	# Efeitos da fome extrema
	if current_hunger > 80:
		modify_sanity(-5)

func get_hunger_percentage() -> float:
	return current_hunger / max_hunger

# Funções de medo
func increase_fear(amount: float) -> void:
	current_fear = clamp(current_fear + amount, 0, max_fear)
	fear_changed.emit(current_fear)
	
	# Efeitos do medo extremo
	if current_fear > 70:
		modify_sanity(-10)

func decrease_fear(amount: float) -> void:
	current_fear = clamp(current_fear - amount, 0, max_fear)
	fear_changed.emit(current_fear)

func get_fear_percentage() -> float:
	return current_fear / max_fear

# Sistema de memórias
func discover_memory(memory_id: String) -> void:
	if memory_id not in discovered_memories:
		discovered_memories.append(memory_id)
		memory_discovered.emit(memory_id)
		modify_sanity(5)  # Descobrir memórias restaura um pouco de sanidade
		print("Memória descoberta: ", memory_id)

func get_memories_discovered() -> int:
	return discovered_memories.size()

func get_memory_progress() -> float:
	return float(discovered_memories.size()) / float(total_memories)

# Sistema de inventário
func add_item_to_inventory(item_data: Dictionary) -> bool:
	if inventory.size() < max_inventory_slots:
		inventory.append(item_data)
		print("Item adicionado ao inventário: ", item_data.get("name", "Item desconhecido"))
		return true
	else:
		print("Inventário cheio!")
		return false

func remove_item_from_inventory(item_name: String) -> bool:
	for i in range(inventory.size()):
		if inventory[i].get("name") == item_name:
			inventory.remove_at(i)
			print("Item removido do inventário: ", item_name)
			return true
	return false

func has_item(item_name: String) -> bool:
	for item in inventory:
		if item.get("name") == item_name:
			return true
	return false

func get_item_count(item_name: String) -> int:
	var count = 0
	for item in inventory:
		if item.get("name") == item_name:
			count += 1
	return count

func get_inventory() -> Array[Dictionary]:
	return inventory.duplicate()

# Funções de estado do jogo
func save_game() -> void:
	var save_data = {
		"sanity": current_sanity,
		"hunger": current_hunger,
		"fear": current_fear,
		"memories": discovered_memories,
		"inventory": inventory,
		"game_time": game_time,
		"current_scene": current_scene,
		"is_night": is_night
	}
	
	var save_file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Jogo salvo com sucesso!")

func load_game() -> bool:
	var save_file = FileAccess.open("user://savegame.dat", FileAccess.READ)
	if save_file:
		var save_data_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		
		if parse_result == OK:
			var save_data = json.data
			current_sanity = save_data.get("sanity", 100.0)
			current_hunger = save_data.get("hunger", 50.0)
			current_fear = save_data.get("fear", 20.0)
			discovered_memories = save_data.get("memories", [])
			inventory = save_data.get("inventory", [])
			game_time = save_data.get("game_time", 0.0)
			current_scene = save_data.get("current_scene", "basement")
			is_night = save_data.get("is_night", false)
			
			print("Jogo carregado com sucesso!")
			return true
	
	print("Não foi possível carregar o jogo.")
	return false

# Função para resetar o jogo
func reset_game() -> void:
	current_sanity = max_sanity
	current_hunger = 50.0
	current_fear = 20.0
	discovered_memories.clear()
	inventory.clear()
	game_time = 0.0
	current_scene = "basement"
	is_night = false
	print("Jogo resetado!")

func _on_day_started() -> void:
	is_night = false
	day_started.emit()
	print("GameManager: Dia começou!")

func _on_night_started() -> void:
	is_night = true
	night_started.emit()
	print("GameManager: Noite começou!")

func display_message(message: String) -> void:
	# Este método será implementado na UI ou em um sistema de mensagens dedicado
	# Por enquanto, apenas imprime no console
	print("MENSAGEM: ", message)


