class_name Item
extends Area2D # Alterado para Area2D

@export var item_name: String = "Item"
@export var item_description: String = "Um item comum."
@export var actions: Array[String] = ["Examinar", "Pegar"]
@export var interaction_range_tiles: int = 1 # Distância de interação em tiles
@export var auto_face_player: bool = true

var tile_position: Vector2i
var is_interactable: bool = true

signal item_clicked(item_node: Node) # Sinal para o Player

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D # Caminho direto

func _ready() -> void:
	# Configurar área de interação
	# A Area2D e CollisionShape2D já devem estar configuradas na cena
	# Se não estiverem, adicione-as manualmente ou via código aqui.
	
	# Conectar sinal da área
	input_event.connect(_on_area_input_event)
	
	# Adicionar ao grupo para que o ItemManager possa encontrá-los
	add_to_group("interactive_items")

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			item_clicked.emit(self) # Emite o sinal para o Player
			print("Item ", item_name, " clicked, emitting signal.")

func handle_action(action: String) -> void:
	# Este método será chamado pelo ItemManager
	# Itens específicos podem sobrescrever isso para ações personalizadas
	match action:
		"Examinar":
			GameManager.display_message(item_name + ": " + item_description)
			print("Examinando: ", item_name)
		"Pegar":
			# Lógica de pegar item (será tratada pelo ItemManager)
			print("Tentando pegar: ", item_name)
		_:
			print("Ação desconhecida para ", item_name, ": ", action)

func set_tile_position(tilemap: TileMap, tile_pos: Vector2i) -> void:
	tile_position = tile_pos
	global_position = tilemap.map_to_local(tile_pos)
	print("Item ", item_name, " positioned at tile ", tile_pos, " world pos ", global_position)
	
func interact(player: Node2D) -> void:
	# Método genérico de interação. Pode ser sobrescrito por itens específicos.
	print("Interagindo com ", item_name)
