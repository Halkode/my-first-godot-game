extends Node

## Autoload que orquestra o fluxo de tratamento de ferimentos:
## abre a tela de tratamento, dispara o minigame correspondente ao
## item escolhido e repassa o resultado ao HealthManager.

signal treatment_screen_opened
signal treatment_screen_closed
signal treatment_completed(part: BodyPart, injury: Injury, quality: float)

## Qualidade usada para itens que ainda não têm minigame próprio.
const PLACEHOLDER_QUALITY: float = 0.6

## Itens de inventário (por nome) aceitos para tratar ferimentos.
## "Bandagem" usa o minigame de enrolar; demais usam qualidade fixa
## até ganharem seu próprio minigame (limpeza, sutura, tala, queimadura).
const TREATMENT_ITEMS := ["Bandagem", "Gaze"]
const MINIGAME_ITEMS := ["Bandagem"]

var _screen: Control
var _bandage_minigame: Control
var is_open: bool = false

var _pending_part: BodyPart
var _pending_injury: Injury
var _pending_item_name: String

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

## Inicia o tratamento de um item a um ferimento específico.
## Para itens com minigame, abre o minigame antes de concluir.
func apply_treatment(part: BodyPart, injury: Injury, item_name: String) -> void:
	if not TREATMENT_ITEMS.has(item_name):
		push_warning("TreatmentManager: item '%s' não é um item de tratamento." % item_name)
		return
	if not InventoryManager or not InventoryManager.has_item(item_name):
		if UIManager:
			UIManager.display_message(
				Localization.tr_format("MSG_NO_ITEM", {"item": item_name})
			)
		return

	if MINIGAME_ITEMS.has(item_name):
		_start_minigame(part, injury, item_name)
	else:
		_finish_treatment(part, injury, item_name, PLACEHOLDER_QUALITY)

func _start_minigame(part: BodyPart, injury: Injury, item_name: String) -> void:
	_pending_part = part
	_pending_injury = injury
	_pending_item_name = item_name

	match item_name:
		"Bandagem":
			if not _bandage_minigame:
				var BandageMinigameScene = load("res://scripts/treatment/minigames/bandage_minigame.gd")
				_bandage_minigame = BandageMinigameScene.new()
				get_tree().root.add_child(_bandage_minigame)
				_bandage_minigame.minigame_completed.connect(_on_minigame_completed)
			_screen.hide()
			_bandage_minigame.reset()
			_bandage_minigame.show()

func _on_minigame_completed(quality: float) -> void:
	if _bandage_minigame:
		_bandage_minigame.hide()
	if _screen and is_open:
		_screen.show()

	_finish_treatment(_pending_part, _pending_injury, _pending_item_name, quality)

	_pending_part = null
	_pending_injury = null
	_pending_item_name = ""

func _finish_treatment(part: BodyPart, injury: Injury, item_name: String, quality: float) -> void:
	InventoryManager.remove_item(item_name)

	injury.treated = true
	injury.treatment_quality = quality

	HealthManager.bleeding_changed.emit(HealthManager.get_total_bleeding())
	HealthManager.pain_changed.emit(HealthManager.get_total_pain())
	treatment_completed.emit(part, injury, quality)

	if UIManager:
		UIManager.display_message(Localization.tr_format("MSG_TREATED", {
			"injury": injury.get_type_name(),
			"part": part.get_part_name(),
			"quality": roundi(quality * 100),
		}))

	if _screen and is_open:
		_screen.refresh()
