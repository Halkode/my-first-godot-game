class_name MovementUtils
extends Node

## Pathfinding A* sobre o grid top-down de tiles quadrados (32x32).
## O caminho é calculado em coordenadas de tile e devolvido em
## coordenadas de mundo (centro de cada tile).

## Movimento em 8 direções. Diagonais custam ~1.41 (distância real),
## então o A* naturalmente prefere caminhos retos quando há empate.
const ALLOW_DIAGONAL: bool = true

static func get_path_to_tile_layers(
	start_pos: Vector2,
	target_pos: Vector2,
	walkable_layer: TileMapLayer,
	obstacle_layer: TileMapLayer
) -> PackedVector2Array:
	if not walkable_layer:
		push_warning("MovementUtils: walkable_layer não fornecido.")
		return PackedVector2Array()

	var start_tile := walkable_layer.local_to_map(walkable_layer.to_local(start_pos))
	var end_tile := walkable_layer.local_to_map(walkable_layer.to_local(target_pos))

	if start_tile == end_tile:
		return PackedVector2Array()

	var walkable := _collect_walkable_tiles(walkable_layer, obstacle_layer)
	if not walkable.has(start_tile) or not walkable.has(end_tile):
		return PackedVector2Array()

	var astar := _build_astar(walkable)

	var start_id := get_point_id(start_tile)
	var end_id := get_point_id(end_tile)
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return PackedVector2Array()

	var world_path := PackedVector2Array()
	for tile_pos in astar.get_point_path(start_id, end_id):
		var local := walkable_layer.map_to_local(Vector2i(tile_pos))
		world_path.append(walkable_layer.to_global(local))
	return world_path

## Conjunto (Dictionary usado como set) dos tiles andáveis: existem no
## layer de chão e não estão cobertos por um obstáculo.
static func _collect_walkable_tiles(
	walkable_layer: TileMapLayer,
	obstacle_layer: TileMapLayer
) -> Dictionary:
	var blocked := {}
	if obstacle_layer:
		for tile in obstacle_layer.get_used_cells():
			blocked[tile] = true

	var walkable := {}
	for tile in walkable_layer.get_used_cells():
		if not blocked.has(tile):
			walkable[tile] = true
	return walkable

static func _build_astar(walkable: Dictionary) -> AStar2D:
	var astar := AStar2D.new()

	for tile in walkable:
		astar.add_point(get_point_id(tile), Vector2(tile))

	for tile in walkable:
		var point_id := get_point_id(tile)

		for offset in Constants.NEIGHBORS_4:
			_try_connect(astar, walkable, tile + offset, point_id)

		if not ALLOW_DIAGONAL:
			continue

		for offset in Constants.NEIGHBORS_DIAGONAL:
			# Impede "cortar quina": a diagonal só vale se os dois tiles
			# ortogonais que a ladeiam também forem andáveis.
			if not walkable.has(Vector2i(tile.x + offset.x, tile.y)):
				continue
			if not walkable.has(Vector2i(tile.x, tile.y + offset.y)):
				continue
			_try_connect(astar, walkable, tile + offset, point_id)

	return astar

static func _try_connect(
	astar: AStar2D,
	walkable: Dictionary,
	to_tile: Vector2i,
	from_id: int
) -> void:
	if not walkable.has(to_tile):
		return
	var to_id := get_point_id(to_tile)
	if not astar.has_point(to_id):
		return
	if not astar.are_points_connected(from_id, to_id):
		astar.connect_points(from_id, to_id)

## Emparelhamento de Cantor: mapeia coordenadas 2D para um id único.
static func get_point_id(tile: Vector2i) -> int:
	var a := tile.x + 10000
	var b := tile.y + 10000
	return (a + b) * (a + b + 1) / 2 + b

static func get_neighbors(tile: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for offset in Constants.NEIGHBORS_4:
		neighbors.append(tile + offset)
	if ALLOW_DIAGONAL:
		for offset in Constants.NEIGHBORS_DIAGONAL:
			neighbors.append(tile + offset)
	return neighbors

## Distância em tiles usada para checar alcance de interação.
## Com diagonais habilitadas usa Chebyshev; sem elas, Manhattan.
static func tile_distance(from_tile: Vector2i, to_tile: Vector2i) -> int:
	var dx := absi(from_tile.x - to_tile.x)
	var dy := absi(from_tile.y - to_tile.y)
	if ALLOW_DIAGONAL:
		return maxi(dx, dy)
	return dx + dy
