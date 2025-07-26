class_name Player
extends CharacterBody2D

@export var move_speed: float = 100.0
@export var arrival_threshold: float = 1.0
@export var max_health: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 50.0

var current_health: float = 100.0
var target_position: Vector2
var path: PackedVector2Array
var is_moving: bool = false
var pending_interaction_item: Node = null
var pending_attack_target: Node = null

# Acessamos os TileMapLayers diretamente
@onready var layer0: TileMapLayer = $"../TileMaps/Layer0"
@onready var layer1: TileMapLayer = $"../TileMaps/Layer1"

func _ready() -> void:
	# Snap initial position to tile center
	var current_tile = layer0.local_to_map(global_position)
	global_position = layer0.map_to_local(current_tile)
	print("Player initial position (snapped to center): ", global_position)

	current_health = max_health

func _unhandled_input(event: InputEvent) -> void:
	if ItemManager and ItemManager.is_menu_visible():
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not ItemManager.is_click_inside_menu(get_global_mouse_position()):
				ItemManager.hide_item_menu()
				get_viewport().set_input_as_handled()
				return
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = get_global_mouse_position()
			
			# Detectar cliques em itens primeiro
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = click_pos
			query.collision_mask = 1  # Ajuste conforme suas collision layers
			query.collide_with_areas = true
			query.collide_with_bodies = true
			
			var results = space_state.intersect_point(query)
			for result in results:
				var collider = result.collider
				# Verificar se é um item clicável
				if collider.is_in_group("items") and collider.has_method("interact"):
					on_item_clicked(collider)
					return
			
			# Por enquanto, sem detecção de inimigos - apenas movimento
			# TODO: Adicionar detecção de inimigos quando necessário
			
			# Resetar qualquer interação ou ataque pendente
			pending_interaction_item = null
			pending_attack_target = null
			
			# Passa os TileMapLayers diretamente para o MovementUtils
			var new_path = MovementUtils.get_path_to_tile_layers(
				global_position,
				click_pos,
				layer0, # Layer walkable
				layer1  # Layer obstacles
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

func _process(_delta):
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
		
		if pending_interaction_item:
			print("Executing pending interaction with ", pending_interaction_item.name)
			if ItemManager:
				ItemManager.show_item_menu(pending_interaction_item, get_global_mouse_position())
			pending_interaction_item = null
			
		if pending_attack_target:
			print("Executing pending attack on ", pending_attack_target.name)
			perform_attack(pending_attack_target)
			pending_attack_target = null
		return
		
	target_position = path[0]
	if target_position.distance_to(global_position) < arrival_threshold:
		print("Next target too close, skipping")
		_advance_to_next_target()
	else:
		print("New target set: ", target_position)

func on_item_clicked(item_node: Node) -> void:
	print("Item clicked: ", item_node.name)
	
	var player_tile_coords = layer0.local_to_map(global_position)
	var item_tile_coords = layer0.local_to_map(item_node.global_position)
	
	var dist_x = abs(player_tile_coords.x - item_tile_coords.x)
	var dist_y = abs(player_tile_coords.y - item_tile_coords.y)
	var manhattan_distance = dist_x + dist_y
	
	print("Player tile: ", player_tile_coords, ", Item tile: ", item_tile_coords, ", Distance: ", manhattan_distance)
	
	if manhattan_distance <= item_node.interaction_range_tiles:
		if ItemManager:
			ItemManager.show_item_menu(item_node, get_global_mouse_position())
	else:
		var closest_reachable_tile_world_pos = _find_closest_reachable_tile_world_pos(item_tile_coords, item_node.interaction_range_tiles)

		if closest_reachable_tile_world_pos != Vector2.INF:
			move_to_interact(closest_reachable_tile_world_pos, item_node)
		else:
			print("Item too far, cannot find reachable tile.")
			ItemManager.display_message("Não consigo alcançar esse item.")

func _find_closest_reachable_tile_world_pos(target_tile_coords: Vector2i, max_range: int) -> Vector2:
	var player_tile_coords = layer0.local_to_map(global_position)
	var min_dist = INF
	var best_world_pos = Vector2.INF

	for dx in range(-max_range, max_range + 1):
		for dy in range(-max_range, max_range + 1):
			if abs(dx) + abs(dy) <= max_range:
				var check_tile = Vector2i(target_tile_coords.x + dx, target_tile_coords.y + dy)

				if layer0.get_cell_source_id(check_tile) != -1 and \
				   layer1.get_cell_source_id(check_tile) == -1:
					
					var current_path = MovementUtils.get_path_to_tile_layers(
						global_position,
						layer0.map_to_local(check_tile),
						layer0,
						layer1
					)
					if not current_path.is_empty():
						var dist_from_player_to_check_tile = abs(player_tile_coords.x - check_tile.x) + abs(player_tile_coords.y - check_tile.y)
						if dist_from_player_to_check_tile < min_dist:
							min_dist = dist_from_player_to_check_tile
							best_world_pos = layer0.map_to_local(check_tile)

	return best_world_pos

func move_to_interact(interaction_world_pos: Vector2, item_node: Node) -> void:
	print("Moving to interact with ", item_node.name, " at ", interaction_world_pos)
	
	pending_interaction_item = item_node
	pending_attack_target = null
	
	var new_path = MovementUtils.get_path_to_tile_layers(
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
		var player_tile_coords = layer0.local_to_map(global_position)
		var item_tile_coords = layer0.local_to_map(item_node.global_position)
		var dist_x = abs(player_tile_coords.x - item_tile_coords.x)
		var dist_y = abs(player_tile_coords.y - item_tile_coords.y)
		var manhattan_distance = dist_x + dist_y

		if manhattan_distance <= item_node.interaction_range_tiles:
			if ItemManager:
				ItemManager.show_item_menu(item_node, get_global_mouse_position())
		else:
			ItemManager.display_message("Não consigo alcançar esse item.")
		pending_interaction_item = null

func move_to_attack(target_node: Node) -> void:
	print("Moving to attack ", target_node.name)
	
	pending_attack_target = target_node
	pending_interaction_item = null
	
	var target_tile_coords = layer0.local_to_map(target_node.global_position)
	# Usando um valor fixo para tile_size já que não temos acesso ao TileSet
	var tile_size = 16 # Ajuste conforme necessário
	var closest_attack_tile_pos = _find_closest_reachable_tile_world_pos(target_tile_coords, int(attack_range / tile_size))
	
	if closest_attack_tile_pos != Vector2.INF:
		var new_path = MovementUtils.get_path_to_tile_layers(
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
			perform_attack(target_node)
	else:
		print("Target too far, cannot find reachable attack tile.")
		ItemManager.display_message("Inimigo muito longe para atacar.")
		pending_attack_target = null

func perform_attack(target: Node) -> void:
	if global_position.distance_to(target.global_position) <= attack_range:
		if CombatSystem:
			CombatSystem.attack(self, target, attack_damage)
			GameManager.modify_sanity(-2)
			GameManager.increase_fear(3)
		else:
			print("CombatSystem não encontrado!")
	else:
		ItemManager.display_message("Inimigo fora do alcance de ataque.")
		print("Inimigo fora do alcance de ataque.")

func take_damage(amount: float) -> void:
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	print("Player recebeu ", amount, " de dano. Saúde atual: ", current_health)
	GameManager.modify_sanity(-5)
	GameManager.increase_fear(10)
	
	if current_health <= 0:
		print("Player morreu!")
		GameManager.display_message("Você sucumbiu à escuridão...")
		get_tree().reload_current_scene()

func get_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health
