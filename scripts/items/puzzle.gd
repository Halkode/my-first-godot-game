class_name Puzzle
extends Item

signal puzzle_solved

@export var is_solved: bool = false
@export var solution_description: String = ""

func _ready() -> void:
	super._ready()
	
	item_name = "Quebra-cabeça"
	item_description = "Um enigma intrigante."
	
	actions = ["Examinar", "Interagir"]

func interact(player: Node2D) -> void:
	if is_solved:
		GameManager.display_message("Este quebra-cabeça já foi resolvido.")
	else:
		show_puzzle_interface()

func handle_action(action: String) -> void:
	match action:
		"Examinar":
			examine_puzzle()
		"Interagir":
			interact(null) # Chama o método interact

func examine_puzzle() -> void:
	var description = item_description
	if is_solved:
		description += " Você já o resolveu. " + solution_description
	else:
		description += " Você precisa resolvê-lo."
	GameManager.display_message(description)

func show_puzzle_interface() -> void:
	# Este método deve ser sobrescrito por quebra-cabeças específicos
	# para exibir sua interface de interação (ex: um minigame, um input de código)
	GameManager.display_message("Você precisa interagir com este quebra-cabeça de uma forma específica.")
	print("Mostrando interface do quebra-cabeça para: ", item_name)

func solve_puzzle() -> void:
	if not is_solved:
		is_solved = true
		puzzle_solved.emit()
		GameManager.display_message("Você resolveu o quebra-cabeça! " + solution_description)
		GameManager.modify_sanity(15) # Recompensa por resolver
		GameManager.decrease_fear(10)
		print("Quebra-cabeça resolvido: ", item_name)
		# Pode adicionar lógica para desbloquear algo, abrir portas, etc.

func reset_puzzle() -> void:
	is_solved = false
	print("Quebra-cabeça resetado: ", item_name)


