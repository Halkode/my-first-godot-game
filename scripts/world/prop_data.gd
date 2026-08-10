class_name PropData
extends Resource

## Descreve um objeto cenográfico posicionável no mundo top-down.
## Cada sprite de assets/isometric_tiles/ tem um .tres correspondente
## em data/props/, gerado por tools/generate_prop_resources.py.

enum Category {
	FLOOR,       # Texturas de chão / tapetes
	WALL,        # Paredes e tijolos
	STRUCTURE,   # Escadas, rampas, arcos, pilares, portas
	FURNITURE,   # Mesas, cadeiras, estantes
	CONTAINER,   # Baús, barris, caixotes
	LIGHT,       # Velas, tochas
	NATURE,      # Árvores, arbustos, rochas
	DECOR,       # Ossos, livros, bandeiras, ouro
}

@export var id: String = ""
@export var display_name: String = ""
@export var category: Category = Category.DECOR
@export var texture: Texture2D

## Região com conteúdo real dentro do PNG de 500x500 (o resto é
## transparente). Usada para recortar o sprite sem margem morta.
@export var content_region: Rect2i = Rect2i()

## Escala sugerida para que o objeto ocupe aproximadamente
## `footprint_tiles` tiles do grid top-down (32x32).
@export var suggested_scale: float = 1.0

## Quantos tiles o objeto deve ocupar no grid.
@export var footprint_tiles: float = 1.0

## Se verdadeiro, bloqueia o movimento do jogador (vai para Layer1).
@export var blocks_movement: bool = false

## Se verdadeiro, o jogador pode interagir (abrir, examinar, acender).
@export var interactable: bool = false

## Luz emitida por este prop (0.0 = nenhuma). Usado pelo LightingSystem.
@export_range(0.0, 1.0) var light_energy: float = 0.0

const CATEGORY_NAMES := {
	Category.FLOOR: "Chão",
	Category.WALL: "Parede",
	Category.STRUCTURE: "Estrutura",
	Category.FURNITURE: "Mobília",
	Category.CONTAINER: "Recipiente",
	Category.LIGHT: "Iluminação",
	Category.NATURE: "Natureza",
	Category.DECOR: "Decoração",
}

func get_category_name() -> String:
	return CATEGORY_NAMES.get(category, "Objeto")

## Cria um Sprite2D já recortado e escalado, centrado no tile.
## Numa câmera top-down o objeto é visto de cima, então ele fica
## centrado no tile em vez de ancorado pela base como no isométrico.
func build_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(content_region)
	sprite.scale = Vector2(suggested_scale, suggested_scale)
	return sprite
