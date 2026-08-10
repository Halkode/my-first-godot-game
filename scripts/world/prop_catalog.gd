extends Node

## Autoload que carrega todos os PropData de data/props/ e permite
## consultá-los por id ou categoria, além de instanciar props no mundo.

const PROPS_DIR := "res://data/props"

var _props: Dictionary = {}

func _ready() -> void:
	_load_all_props()

func _load_all_props() -> void:
	var dir := DirAccess.open(PROPS_DIR)
	if not dir:
		push_warning("PropCatalog: não foi possível abrir %s" % PROPS_DIR)
		return

	for file_name in dir.get_files():
		## Builds exportadas renomeiam .tres para .remap
		var resource_name := file_name.trim_suffix(".remap")
		if not resource_name.ends_with(".tres"):
			continue
		var prop: PropData = load("%s/%s" % [PROPS_DIR, resource_name])
		if prop:
			_props[prop.id] = prop

	print("PropCatalog: %d props carregados." % _props.size())

func get_prop(id: String) -> PropData:
	return _props.get(id)

func get_all() -> Array[PropData]:
	var result: Array[PropData] = []
	for prop in _props.values():
		result.append(prop)
	return result

func get_by_category(category: PropData.Category) -> Array[PropData]:
	var result: Array[PropData] = []
	for prop in _props.values():
		if prop.category == category:
			result.append(prop)
	return result

## Instancia um prop como Node2D pronto para ser adicionado à cena,
## já com sprite recortado, colisão (se bloqueia movimento) e luz
## (se emite). A posição deve ser definida pelo chamador.
func spawn_prop(id: String) -> Node2D:
	var prop := get_prop(id)
	if not prop:
		push_warning("PropCatalog: prop '%s' não encontrado." % id)
		return null

	var root := Node2D.new()
	root.name = prop.id
	root.y_sort_enabled = true

	root.add_child(prop.build_sprite())

	if prop.blocks_movement:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		## Footprint no grid isométrico: largura do tile x metade da altura
		rect.size = Vector2(32.0 * prop.footprint_tiles, 16.0 * prop.footprint_tiles)
		shape.shape = rect
		body.add_child(shape)
		root.add_child(body)

	if prop.light_energy > 0.0:
		var light := PointLight2D.new()
		light.energy = prop.light_energy
		light.texture = _get_light_texture()
		light.texture_scale = 2.0
		light.color = Color(1.0, 0.85, 0.6)
		root.add_child(light)

	return root

## PointLight2D não renderiza sem textura. Geramos um gradiente radial
## uma única vez e reutilizamos em todos os props que emitem luz.
static var _light_texture: GradientTexture2D

static func _get_light_texture() -> GradientTexture2D:
	if _light_texture:
		return _light_texture

	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))

	_light_texture = GradientTexture2D.new()
	_light_texture.gradient = gradient
	_light_texture.width = 128
	_light_texture.height = 128
	_light_texture.fill = GradientTexture2D.FILL_RADIAL
	_light_texture.fill_from = Vector2(0.5, 0.5)
	_light_texture.fill_to = Vector2(1.0, 0.5)
	return _light_texture
