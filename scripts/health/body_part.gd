class_name BodyPart
extends Resource

## Uma parte do corpo do personagem, contendo seus ferimentos ativos.

enum Id {
	HEAD,
	TORSO,
	ARM_LEFT,
	ARM_RIGHT,
	LEG_LEFT,
	LEG_RIGHT,
}

@export var id: Id = Id.TORSO
@export var injuries: Array[Injury] = []

const ID_NAMES := {
	Id.HEAD: "Cabeça",
	Id.TORSO: "Torso",
	Id.ARM_LEFT: "Braço esquerdo",
	Id.ARM_RIGHT: "Braço direito",
	Id.LEG_LEFT: "Perna esquerda",
	Id.LEG_RIGHT: "Perna direita",
}

func get_part_name() -> String:
	return ID_NAMES.get(id, "Parte do corpo")

func add_injury(injury: Injury) -> void:
	injuries.append(injury)

func remove_injury(injury: Injury) -> void:
	injuries.erase(injury)

func get_total_bleeding() -> float:
	var total := 0.0
	for injury in injuries:
		total += injury.get_effective_bleeding()
	return total

func get_total_pain() -> float:
	var total := 0.0
	for injury in injuries:
		total += injury.get_effective_pain()
	return total

func has_injuries() -> bool:
	return not injuries.is_empty()
