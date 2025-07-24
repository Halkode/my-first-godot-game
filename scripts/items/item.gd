class_name Item
extends Node2D

@export var item_name: String = "Item"
@export var interaction_distance: float = 32.0
@export var auto_face_player: bool = true

var tile_position: Vector2i
var is_interactable: bool = true

signal item_interacted(item: Item, player: Node2D)

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D

func _ready() -> void:
	# Configurar área de interação
	setup_interaction_area()
	
	# Conectar sinal da área
	if interaction_area:
		interaction_area.input_event.connect(_on_area_input_event)

func setup_interaction_area() -> void:
	if not interaction_area:
		interaction_area = Area2D.new()
		add_child(interaction_area)
	
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(32, 32)  # Ajuste conforme necessário
		collision_shape.shape = shape
		interaction_area.add_child(collision_shape)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			request_interaction()

func request_interaction() -> void:
	if not is_interactable:
		return
		
	# Emitir sinal para o sistema de interação
	item_interacted.emit(self, null)
	print("Item ", item_name, " requesting interaction")

func interact(player: Node2D) -> void:
	print("Interacting with ", item_name)
	# Override this method in specific items
	show_interaction_menu(player)

func show_interaction_menu(player: Node2D) -> void:
	# Método base - override em itens específicos
	print("No specific interaction defined for ", item_name)

func get_interaction_position() -> Vector2:
	# Retorna a posição onde o player deve ir para interagir
	return global_position

func set_tile_position(tilemap: TileMapLayer, tile_pos: Vector2i) -> void:
	tile_position = tile_pos
	global_position = tilemap.map_to_local(tile_pos)
	print("Item ", item_name, " positioned at tile ", tile_pos, " world pos ", global_position)
