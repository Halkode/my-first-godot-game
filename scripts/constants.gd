class_name Constants
extends RefCounted

## Constantes globais do grid. O jogo usa projeção top-down com tiles
## quadrados de 32x32.

const TILE_SIZE: int = 32
const TILE_VECTOR := Vector2i(TILE_SIZE, TILE_SIZE)

## Vizinhos ortogonais (cima, baixo, esquerda, direita).
const NEIGHBORS_4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

## Diagonais, usadas quando o movimento em 8 direções está habilitado.
const NEIGHBORS_DIAGONAL: Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(-1, -1),
]
