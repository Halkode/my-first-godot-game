class_name Player
extends CharacterBody2D

@export var move_speed: float = 100.0
@export var arrival_threshold: float = 1.0 # Smaller threshold for precise center alignment
@export var max_health: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 50.0 # Alcance do ataque em pixels

var current_health: float = 100.0
var target_position: Vector2
var path: PackedVector2Array
var is_moving: bool = false
var pending_interaction_item: Node = null # Alterado para Node, pois Item será um script customizado
var pending_attack_target: Node = null # Novo: alvo de ataque pendente

@onready var layer0: TileMap = $"../../Layer0" # Corrigido o caminho e o tipo para TileMap
@onready var layer1: TileMap = $"../../Layer1" # Corrigido o caminho e o tipo para TileMap
@onready var item_manager: ItemManager = $"../../ItemManager" # Corrigido o caminho
@onready var combat_system: CombatSystem = $"../../CombatSystem" # Referência ao sistema de combate

func _ready() -> void:
	# Snap initial position to tile center
	var current_tile = layer0.local_to_map(global_position)
	global_position = layer0.map_to_local(current_tile)
	print("Player initial position (snapped to center): ", global_position)

	current_health = max_health

func _unhandled_input(event: InputEvent) -> void:
	# Se o menu de itens está visível (gerenciado pelo ItemManager),
	# o player não deve iniciar um novo movimento de clique no mundo.
	if item_manager and item_manager.is_menu_visible():
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Se clicou fora do menu, feche-o e consuma o evento
			if not item_manager.is_click_inside_menu(get_global_mouse_position()):
				item_manager.hide_item_menu()
				get_viewport().set_input_as_handled()
				return
		return # Consome o input se o menu está visível para evitar movimento indesejado

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = get_global_mouse_position()
			
			# Tentar encontrar um alvo de ataque primeiro
			var clicked_object = get_viewport().get_mouse_object(click_pos) # Isso pode precisar de um grupo ou área específica para inimigos
			if clicked_object and clicked_object.is_in_group("enemies"):
				pending_attack_target = clicked_object
				pending_interaction_item = null # Limpa interação pendente se for atacar
				move_to_attack(clicked_object)
				return # Consome o evento para evitar movimento

			# Resetar qualquer interação ou ataque pendente ao iniciar um novo movimento
			pending_interaction_item = null
			pending_attack_target = null
			
			var new_path = MovementUtils.get_path_to_tile(
				global_position,
				click_pos,
				layer0, # Passa o nó TileMap
				layer1  # Passa o nó TileMap
			)
			
			if not new_path.is_empty():
				path = new_path
				is_moving = true
				target_position = path[0]
				print("Path accepted, first target: ", target_position)
				
				if target_position.distance_to(global_position) < arrival_threshold:
					print("Warning: First target too close to current position!")
					_advance_to_next_target()
			else:
				print("Path was empty, movement cancelled")

func _process(delta: float) -> void:
	# Atualiza a posição do player no grid para lógica de proximidade
	# (se você precisar dela em _process)
	# var current_tile_coords = layer0.local_to_map(global_position)
	pass

func _physics_process(delta: float) -> void:
	if not is_moving or path.is_empty():
		return
		
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target < arrival_threshold:
		global_position = target_position
		_advance_to_next_target()
	else:
		var direction = (target_position - global_position).normalized()
		var movement = direction * move_speed * delta
		if movement.length() > distance_to_target:
			movement = direction * distance_to_target
		global_position += movement

func _advance_to_next_target() -> void:
	path.remove_at(0)
	print("Point reached, remaining points: ", path.size())
	
	if path.is_empty():
		print("Path completed")
		is_moving = false
		
		# Se há uma interação pendente, executá-la agora
		if pending_interaction_item:
			print("Executing pending interaction with ", pending_interaction_item.name)
			if item_manager:
				item_manager.show_item_menu(pending_interaction_item, get_global_mouse_position()) # Passa a posição do player
			pending_interaction_item = null # Limpa a interação pendente
			
		# Se há um ataque pendente, executá-lo agora
		if pending_attack_target:
			print("Executing pending attack on ", pending_attack_target.name)
			perform_attack(pending_attack_target)
			pending_attack_target = null # Limpa o alvo de ataque pendente
		return
		
	target_position = path[0]
	if target_position.distance_to(global_position) < arrival_threshold:
		print("Next target too close, skipping")
		_advance_to_next_target()
	else:
		print("New target set: ", target_position)

# Função chamada pelo ItemManager quando um item é clicado
func on_item_clicked(item_node: Node) -> void: # Recebe o nó do item clicado
	print("Item clicked: ", item_node.name)
	
	# Calcule a posição do player no grid
	var player_tile_coords = layer0.local_to_map(global_position)
	# Calcule a posição do item no grid
	var item_tile_coords = layer0.local_to_map(item_node.global_position)
	
	# Calcule a distância de Manhattan
	var dist_x = abs(player_tile_coords.x - item_tile_coords.x)
	var dist_y = abs(player_tile_coords.y - item_tile_coords.y)
	var manhattan_distance = dist_x + dist_y
	
	print("Player tile: ", player_tile_coords, ", Item tile: ", item_tile_coords, ", Distance: ", manhattan_distance)
	
	# Verifica se o jogador está dentro do alcance de interação do item
	# Assumimos que o item_node tem uma propriedade \'interaction_range_tiles\'
	if manhattan_distance <= item_node.interaction_range_tiles:
		# Se já está perto, mostra o menu imediatamente
		if item_manager:
			item_manager.show_item_menu(item_node, get_global_mouse_position()) # Passa a posição do clique para o menu
	else:
		# Se está muito longe, move o player para perto do item
		# Encontre um tile adjacente ao item que esteja dentro do alcance
		var closest_reachable_tile_pos = _find_closest_reachable_tile_world_pos(item_tile_coords, item_node.interaction_range_tiles)

		if closest_reachable_tile_pos != Vector2.INF:
			move_to_interact(closest_reachable_tile_pos, item_node)
		else:
			print("Item too far, cannot find reachable tile.")
			item_manager.display_message("Não consigo alcançar esse item.") # Exibe mensagem via ItemManager

# Função auxiliar para encontrar a posição no mundo do tile mais próximo alcançável
func _find_closest_reachable_tile_world_pos(target_tile_coords: Vector2i, range: int) -> Vector2:
	var player_tile_coords = layer0.local_to_map(global_position)
	var min_dist = INF
	var best_world_pos = Vector2.INF

	for dx in range(-range, range + 1):
		for dy in range(-range, range + 1):
			if abs(dx) + abs(dy) <= range: # Distância de Manhattan
				var check_tile = Vector2i(target_tile_coords.x + dx, target_tile_coords.y + dy)
				
				# IMPORTANT: Adicione sua lógica de verificação de "passabilidade" aqui.
				# Exemplo (assumindo que layer0 é o TileMap principal e layer1 é para obstáculos):
				if layer0.get_cell_source_id(0, check_tile) != -1 and \
				   layer1.get_cell_source_id(0, check_tile) == -1: # Verifica se o tile existe em layer0 e não é um obstáculo em layer1
					
					var current_path = MovementUtils.get_path_to_tile(
						global_position,
						layer0.map_to_local(check_tile),
						layer0,
						layer1
					)
					if not current_path.is_empty():
						var dist_from_player_to_check_tile = abs(player_tile_coords.x - check_tile.x) + abs(player_tile_coords.y - check_tile.y)
						# Prioriza tiles que estão dentro do alcance de ataque/interação
						if dist_from_player_to_check_tile < min_dist:
							min_dist = dist_from_player_to_check_tile
							best_world_pos = layer0.map_to_local(check_tile)
	return best_world_pos

# Função para iniciar o movimento em direção a uma posição de interação
func move_to_interact(interaction_world_pos: Vector2, item_node: Node) -> void:
	print("Moving to interact with ", item_node.name, " at ", interaction_world_pos)
	
	pending_interaction_item = item_node # Armazena o item para interagir quando chegar
	pending_attack_target = null # Limpa qualquer alvo de ataque pendente
	
	var new_path = MovementUtils.get_path_to_tile(
		global_position,
		interaction_world_pos,
		layer0,
		layer1
	)
	
	if not new_path.is_empty():
		path = new_path
		is_moving = true
		target_position = path[0]
		print("Moving to interaction position, first target: ", target_position)
	else:
		print("Cannot create path to interaction position, executing immediately if already close.")
		# Se não conseguir criar um caminho, mas já está perto, tenta interagir
		var player_tile_coords = layer0.local_to_map(global_position)
		var item_tile_coords = layer0.local_to_map(item_node.global_position)
		var dist_x = abs(player_tile_coords.x - item_tile_coords.x)
		var dist_y = abs(player_tile_coords.y - item_tile_coords.y)
		var manhattan_distance = dist_x + dist_y

		if manhattan_distance <= item_node.interaction_range_tiles:
			if item_manager:
				item_manager.show_item_menu(item_node, get_global_mouse_position())
		else:
			item_manager.display_message("Não consigo alcançar esse item.")
		pending_interaction_item = null # Limpa a interação pendente se não houver movimento

# Novo: Função para iniciar o movimento em direção a um alvo de ataque
func move_to_attack(target_node: Node) -> void:
	print("Moving to attack ", target_node.name)
	
	pending_attack_target = target_node # Armazena o alvo para atacar quando chegar
	pending_interaction_item = null # Limpa qualquer interação pendente
	
	var target_tile_coords = layer0.local_to_map(target_node.global_position)
	var closest_attack_tile_pos = _find_closest_reachable_tile_world_pos(target_tile_coords, int(attack_range / layer0.tile_set.tile_size.x)) # Converte range para tiles
	
	if closest_attack_tile_pos != Vector2.INF:
		var new_path = MovementUtils.get_path_to_tile(
			global_position,
			closest_attack_tile_pos,
			layer0,
			layer1
		)
		
		if not new_path.is_empty():
			path = new_path
			is_moving = true
			target_position = path[0]
			print("Moving to attack position, first target: ", target_position)
		else:
			print("Cannot create path to attack position, attempting attack if close enough.")
			perform_attack(target_node) # Tenta atacar se já estiver perto
	else:
		print("Target too far, cannot find reachable attack tile.")
		item_manager.display_message("Inimigo muito longe para atacar.")
		pending_attack_target = null # Limpa o alvo se não for possível alcançar

# Novo: Função para realizar o ataque
func perform_attack(target: Node) -> void:
	if global_position.distance_to(target.global_position) <= attack_range:
		if combat_system:
			combat_system.attack(self, target, attack_damage)
			GameManager.modify_sanity(-2) # Pequena perda de sanidade ao atacar
			GameManager.increase_fear(3) # Aumenta o medo
		else:
			print("CombatSystem não encontrado!")
	else:
		item_manager.display_message("Inimigo fora do alcance de ataque.")
		print("Inimigo fora do alcance de ataque.")

# Novo: Função para receber dano
func take_damage(amount: float) -> void:
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	print("Player recebeu ", amount, " de dano. Saúde atual: ", current_health)
	GameManager.modify_sanity(-5) # Perde sanidade ao receber dano
	GameManager.increase_fear(10) # Aumenta o medo
	
	if current_health <= 0:
		print("Player morreu!")
		GameManager.display_message("Você sucumbiu à escuridão...")
		# Lógica de game over
		get_tree().reload_current_scene() # Recarrega a cena para reiniciar

func get_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health


