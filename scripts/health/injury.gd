class_name Injury
extends Resource

## Representa um ferimento individual em uma parte do corpo.

enum Type {
	CUT_SHALLOW,   # Corte superficial
	CUT_DEEP,      # Corte profundo
	BURN,          # Queimadura
	FRACTURE,      # Fratura
	INFECTION,     # Infecção
}

@export var type: Type = Type.CUT_SHALLOW
@export_range(0.0, 1.0) var severity: float = 0.5
## HP perdido por segundo enquanto o ferimento sangra
@export var bleeding_rate: float = 0.0
## Dor contribuída por este ferimento (0-1)
@export_range(0.0, 1.0) var pain: float = 0.0
## Chance base de infecção enquanto não tratado (rolada por tick futuro)
@export_range(0.0, 1.0) var infection_chance: float = 0.0
@export var treated: bool = false
@export_range(0.0, 1.0) var treatment_quality: float = 0.0

const TYPE_KEYS := {
	Type.CUT_SHALLOW: "INJURY_CUT_SHALLOW",
	Type.CUT_DEEP: "INJURY_CUT_DEEP",
	Type.BURN: "INJURY_BURN",
	Type.FRACTURE: "INJURY_FRACTURE",
	Type.INFECTION: "INJURY_INFECTION",
}

func get_type_name() -> String:
	return TranslationServer.translate(TYPE_KEYS.get(type, "INJURY_CUT_SHALLOW"))

## Sangramento efetivo considerando tratamento aplicado
func get_effective_bleeding() -> float:
	if treated:
		return bleeding_rate * (1.0 - treatment_quality)
	return bleeding_rate

## Dor efetiva considerando tratamento aplicado
func get_effective_pain() -> float:
	if treated:
		return pain * (1.0 - treatment_quality * 0.5)
	return pain

## Fábrica conveniente para criar ferimentos com valores padrão por tipo
static func create(injury_type: Type, injury_severity: float = 0.5) -> Injury:
	var injury := Injury.new()
	injury.type = injury_type
	injury.severity = clampf(injury_severity, 0.0, 1.0)
	match injury_type:
		Type.CUT_SHALLOW:
			injury.bleeding_rate = 0.3 * injury.severity
			injury.pain = 0.15 * injury.severity
			injury.infection_chance = 0.1 * injury.severity
		Type.CUT_DEEP:
			injury.bleeding_rate = 1.0 * injury.severity
			injury.pain = 0.4 * injury.severity
			injury.infection_chance = 0.3 * injury.severity
		Type.BURN:
			injury.bleeding_rate = 0.0
			injury.pain = 0.6 * injury.severity
			injury.infection_chance = 0.4 * injury.severity
		Type.FRACTURE:
			injury.bleeding_rate = 0.1 * injury.severity
			injury.pain = 0.8 * injury.severity
			injury.infection_chance = 0.05 * injury.severity
		Type.INFECTION:
			injury.bleeding_rate = 0.0
			injury.pain = 0.3 * injury.severity
			injury.infection_chance = 0.0
	return injury
