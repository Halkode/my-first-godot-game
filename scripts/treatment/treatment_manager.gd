extends Node

## Autoload que orquestra o fluxo de tratamento de ferimentos:
## abre a tela de tratamento, aplica o item escolhido e repassa o
## resultado ao HealthManager.
##
## A partir do Sprint 3 a "quality" virá de um minigame por tipo de
## ferimento. Por ora usamos um valor fixo (aplicação "sem treino").

signal treatment_screen_opened
signal treatment_screen_closed
signal treatment_completed(part: BodyPart, injury: Injury, quality: float)

const PLACEHOLDER_QUALITY: float = 0.6

## Itens de inventário (por nome) aceitos para tratar ferimentos.
## TODO(Sprint 3+): mapear item -> minigame específico.
const TREATMENT_ITEMS := ["Bandagem", "Gaze"]

var _screen: Control
var is_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_treatment_screen"):
		toggle_screen()
		get_viewport().set_input_as_handled()

func toggle_screen() -> void:
	if is_open:
		close_screen()
	else:
		open_screen()

func open_screen() -> void:
	if is_open:
		return
	is_open = true
	if not _screen:
		var TreatmentScreenScene = load("res://scripts/ui/treatment_screen.gd")
		_screen = TreatmentScreenScene.new()
		get_tree().root.add_child(_screen)
	_screen.refresh()
	_screen.show()
	get_tree().paused = true
	treatment_screen_opened.emit()

func close_screen() -> void:
	if not is_open:
		return
	is_open = false
	if _screen:
		_screen.hide()
	get_tree().paused = false
	treatment_screen_closed.emit()

## Lista de itens do inventário do jogador aplicáveis a tratamentos.
func get_available_treatment_items() -> Array[String]:
	var available: Array[String] = []
	if not InventoryManager:
		return available
	for item_name in TREATMENT_ITEMS:
		if InventoryManager.has_item(item_name):
			available.append(item_name)
	return available

## Aplica o tratamento de um item a um ferimento específico.
## Consome o item do inventário e marca o ferimento como tratado.
func apply_treatment(part: BodyPart, injury: Injury, item_name: String) -> void:
	if not TREATMENT_ITEMS.has(item_name):
		push_warning("TreatmentManager: item '%s' não é um item de tratamento." % item_name)
		return
	if not InventoryManager or not InventoryManager.has_item(item_name):
		if UIManager:
			UIManager.display_message("Você não tem %s." % item_name)
		return

	InventoryManager.remove_item(item_name)

	var quality := PLACEHOLDER_QUALITY
	injury.treated = true
	injury.treatment_quality = quality

	HealthManager.bleeding_changed.emit(HealthManager.get_total_bleeding())
	HealthManager.pain_changed.emit(HealthManager.get_total_pain())
	treatment_completed.emit(part, injury, quality)

	if UIManager:
		UIManager.display_message("%s tratado em %s (qualidade %d%%)." % [
			injury.get_type_name(), part.get_part_name(), roundi(quality * 100)
		])
