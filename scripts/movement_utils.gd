class_name MovementUtils
extends Node

static func get_path_to_tile(
	start_pos: Vector2,
	target_pos: Vector2,
	tilemap: TileMap,
	blocked_layer: TileMap  # Mantemos o mesmo parâmetro por compatibilidade
) -> PackedVector2Array:
	print("Start pos (world): ", start_pos)
	print("Target pos (world): ", target_pos)
	
	# Acessa os layers do TileMap
	var walkable_layer: TileMapLayer = tilemap.get_layer(0) if tilemap.get_layers_count() > 0 else null
	var obstacle_layer: TileMapLayer = tilemap.get_layer(1) if tilemap.get_layers_count() > 1 else null
	
	if not walkable_layer:
		print("No walkable layer found")
		return PackedVector2Array([])
	
	# Convert world positions to tile coordinates
	var start_tile = walkable_layer.local_to_map(start_pos)
	var end_tile = walkable_layer.local_to_map(target_pos)
	
	print("Start tile (map): ", start_tile)
	print("End tile (map): ", end_tile)
	
	# If start and end are the same tile, return empty path
	if start_tile == end_tile:
		print("Start and end tiles are the same")
		return PackedVector2Array([])
	
	# Get all walkable tiles (excluding blocked tiles)
	var all_tiles = walkable_layer.get_used_cells() # Godot 4: sem parâmetro de layer
	var blocked_tiles: Array[Vector2i] = []
	
	if obstacle_layer:
		blocked_tiles = obstacle_layer.get_used_cells()
	
	var walkable_tiles: Array[Vector2i] = []
	for tile in all_tiles:
		if not blocked_tiles.has(tile):
			walkable_tiles.append(tile)
	
	print("Total tiles: ", all_tiles.size(), ", Blocked tiles: ", blocked_tiles.size(), ", Walkable tiles: ", walkable_tiles.size())
	
	# Create AStar2D pathfinder
	var astar = AStar2D.new()
	
	# Add points for all walkable tiles
	for tile in walkable_tiles:
		var point_id = get_point_id(tile)
		# Store tile coordinates for pathfinding
		astar.add_point(point_id, Vector2(tile))
	
	# Connect points with their neighbors
	for tile in walkable_tiles:
		var point_id = get_point_id(tile)
		
		# Check orthogonal neighbors for isometric grid
		for neighbor in get_neighbors(tile):
			if walkable_tiles.has(neighbor):
				var neighbor_id = get_point_id(neighbor)
				if not astar.has_point(neighbor_id):
					continue # Skip if neighbor is not a valid point in astar
				if not astar.are_points_connected(point_id, neighbor_id):
					astar.connect_points(point_id, neighbor_id)
	
	# Get start and end point IDs
	var start_id = get_point_id(start_tile)
	var end_id = get_point_id(end_tile)
	
	# Return empty path if either start or end is not in the graph
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		print("No valid path: start or end point not in graph")
		return PackedVector2Array([])
	
	# Get path in tile coordinates
	var tile_path = astar.get_point_path(start_id, end_id)
	
	# Convert tile path to world coordinates
	var world_path: PackedVector2Array = PackedVector2Array([])
	for tile_pos in tile_path:
		var world_pos = walkable_layer.map_to_local(Vector2i(tile_pos))
		# Include all points to ensure precise center-to-center movement
		world_path.append(world_pos)
		print("Adding world pos to path: ", world_pos)
	
	print("Final path length: ", world_path.size())
	if world_path.is_empty():
		print("Warning: Generated path is empty!")
	else:
		print("First path point: ", world_path[0])
	return world_path

static func get_point_id(tile: Vector2i) -> int:
	# Convert 2D coordinates to unique ID
	var a = tile.x + 10000
	var b = tile.y + 10000
	return (a + b) * (a + b + 1) / 2 + b

static func get_neighbors(tile: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	# Only orthogonal neighbors for isometric grid
	neighbors.append(Vector2i(tile.x + 1, tile.y))
	neighbors.append(Vector2i(tile.x - 1, tile.y))
	neighbors.append(Vector2i(tile.x, tile.y + 1))
	neighbors.append(Vector2i(tile.x, tile.y - 1))
	return neighbors

# Nova função que aceita TileMapLayers diretamente
static func get_path_to_tile_layers(
	start_pos: Vector2,
	target_pos: Vector2,
	walkable_layer: TileMapLayer,
	obstacle_layer: TileMapLayer
) -> PackedVector2Array:
	print("Start pos (world): ", start_pos)
	print("Target pos (world): ", target_pos)
	
	if not walkable_layer:
		print("No walkable layer provided")
		return PackedVector2Array([])
	
	# Convert world positions to tile coordinates
	var start_tile = walkable_layer.local_to_map(start_pos)
	var end_tile = walkable_layer.local_to_map(target_pos)
	
	print("Start tile (map): ", start_tile)
	print("End tile (map): ", end_tile)
	
	# If start and end are the same tile, return empty path
	if start_tile == end_tile:
		print("Start and end tiles are the same")
		return PackedVector2Array([])
	
	# Get all walkable tiles (excluding blocked tiles)
	var all_tiles = walkable_layer.get_used_cells()
	var blocked_tiles: Array[Vector2i] = []
	
	if obstacle_layer:
		blocked_tiles = obstacle_layer.get_used_cells()
	
	var walkable_tiles: Array[Vector2i] = []
	for tile in all_tiles:
		if not blocked_tiles.has(tile):
			walkable_tiles.append(tile)
	
	print("Total tiles: ", all_tiles.size(), ", Blocked tiles: ", blocked_tiles.size(), ", Walkable tiles: ", walkable_tiles.size())
	
	# Create AStar2D pathfinder
	var astar = AStar2D.new()
	
	# Add points for all walkable tiles
	for tile in walkable_tiles:
		var point_id = get_point_id(tile)
		# Store tile coordinates for pathfinding
		astar.add_point(point_id, Vector2(tile))
	
	# Connect points with their neighbors
	for tile in walkable_tiles:
		var point_id = get_point_id(tile)
		
		# Check orthogonal neighbors for isometric grid
		for neighbor in get_neighbors(tile):
			if walkable_tiles.has(neighbor):
				var neighbor_id = get_point_id(neighbor)
				if not astar.has_point(neighbor_id):
					continue # Skip if neighbor is not a valid point in astar
				if not astar.are_points_connected(point_id, neighbor_id):
					astar.connect_points(point_id, neighbor_id)
	
	# Get start and end point IDs
	var start_id = get_point_id(start_tile)
	var end_id = get_point_id(end_tile)
	
	# Return empty path if either start or end is not in the graph
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		print("No valid path: start or end point not in graph")
		return PackedVector2Array([])
	
	# Get path in tile coordinates
	var tile_path = astar.get_point_path(start_id, end_id)
	
	# Convert tile path to world coordinates
	var world_path: PackedVector2Array = PackedVector2Array([])
	for tile_pos in tile_path:
		var world_pos = walkable_layer.map_to_local(Vector2i(tile_pos))
		# Include all points to ensure precise center-to-center movement
		world_path.append(world_pos)
		print("Adding world pos to path: ", world_pos)
	
	print("Final path length: ", world_path.size())
	if world_path.is_empty():
		print("Warning: Generated path is empty!")
	else:
		print("First path point: ", world_path[0])
	return world_path
