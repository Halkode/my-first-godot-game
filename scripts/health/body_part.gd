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

const ID_KEYS := {
	Id.HEAD: "BODY_HEAD",
	Id.TORSO: "BODY_TORSO",
	Id.ARM_LEFT: "BODY_ARM_LEFT",
	Id.ARM_RIGHT: "BODY_ARM_RIGHT",
	Id.LEG_LEFT: "BODY_LEG_LEFT",
	Id.LEG_RIGHT: "BODY_LEG_RIGHT",
}

func get_part_name() -> String:
	return TranslationServer.translate(ID_KEYS.get(id, "BODY_TORSO"))

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
