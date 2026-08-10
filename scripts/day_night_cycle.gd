extends Node

## Ciclo de dia/noite. Um dia completo (24h no jogo) dura
## DAY_CYCLE_MINUTES minutos reais.
##
## Fases do dia (em horas do jogo):
##   05:00 - 07:00  Amanhecer
##   07:00 - 18:00  Dia
##   18:00 - 20:00  Anoitecer
##   20:00 - 05:00  Noite
##
## A cor ambiente é interpolada continuamente e aplicada a um
## CanvasModulate, deixando o mundo escuro e opressivo à noite.

signal day_started
signal night_started
signal phase_changed(phase: Phase)
signal hour_passed(hour: int)
signal new_day(day_number: int)

enum Phase { DAWN, DAY, DUSK, NIGHT }

## Duração real de um ciclo completo de 24h no jogo.
const DAY_CYCLE_MINUTES: float = 25.0
const DAY_CYCLE_SECONDS: float = DAY_CYCLE_MINUTES * 60.0
const HOURS_PER_DAY: float = 24.0

## Quantas horas do jogo passam por segundo real.
const GAME_HOURS_PER_SECOND: float = HOURS_PER_DAY / DAY_CYCLE_SECONDS

const DAWN_START: float = 5.0
const DAY_START: float = 7.0
const DUSK_START: float = 18.0
const NIGHT_START: float = 20.0

## Cor ambiente de cada fase. Noite bem escura e azulada (Darkwood),
## amanhecer/anoitecer alaranjados, dia com leve dessaturação fria.
const PHASE_COLORS := {
	Phase.DAWN: Color(0.55, 0.45, 0.50),
	Phase.DAY: Color(0.92, 0.92, 0.88),
	Phase.DUSK: Color(0.55, 0.38, 0.35),
	Phase.NIGHT: Color(0.16, 0.18, 0.30),
}

## Hora do jogo em que o dia começa numa partida nova.
@export var starting_hour: float = 8.0

## Multiplicador de velocidade do tempo (para debug/teste).
@export var time_scale: float = 1.0

var current_hour: float = 8.0
var day_number: int = 1
var current_phase: Phase = Phase.DAY

var _canvas_modulate: CanvasModulate
var _last_reported_hour: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	current_hour = starting_hour
	current_phase = _phase_for_hour(current_hour)
	_last_reported_hour = int(current_hour)
	_setup_canvas_modulate.call_deferred()

func _setup_canvas_modulate() -> void:
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "DayNightModulate"
	get_tree().root.add_child(_canvas_modulate)
	_apply_ambient_color()

func _process(delta: float) -> void:
	var previous_hour := current_hour
	current_hour += delta * GAME_HOURS_PER_SECOND * time_scale

	if current_hour >= HOURS_PER_DAY:
		current_hour -= HOURS_PER_DAY
		day_number += 1
		new_day.emit(day_number)

	_check_hour_tick()
	_check_phase_transition(previous_hour)
	_apply_ambient_color()

	GameManager.is_night = is_night()

func _check_hour_tick() -> void:
	var whole_hour := int(current_hour)
	if whole_hour != _last_reported_hour:
		_last_reported_hour = whole_hour
		hour_passed.emit(whole_hour)

func _check_phase_transition(_previous_hour: float) -> void:
	var new_phase := _phase_for_hour(current_hour)
	if new_phase == current_phase:
		return

	var was_night := current_phase == Phase.NIGHT
	current_phase = new_phase
	phase_changed.emit(current_phase)

	if new_phase == Phase.DAWN and was_night:
		day_started.emit()
		print("O dia começou. Dia %d." % day_number)
	elif new_phase == Phase.NIGHT:
		night_started.emit()
		print("A noite caiu. Dia %d." % day_number)

func _phase_for_hour(hour: float) -> Phase:
	if hour >= NIGHT_START or hour < DAWN_START:
		return Phase.NIGHT
	if hour < DAY_START:
		return Phase.DAWN
	if hour < DUSK_START:
		return Phase.DAY
	return Phase.DUSK

## Cor ambiente interpolada suavemente entre a fase atual e a próxima,
## para que a transição não seja um corte abrupto.
func _current_ambient_color() -> Color:
	var phase_start := _phase_start_hour(current_phase)
	var phase_end := _phase_end_hour(current_phase)

	var length := phase_end - phase_start
	if length <= 0.0:
		length += HOURS_PER_DAY

	var elapsed := current_hour - phase_start
	if elapsed < 0.0:
		elapsed += HOURS_PER_DAY

	var progress := clampf(elapsed / length, 0.0, 1.0)
	var next_phase := _next_phase(current_phase)
	return PHASE_COLORS[current_phase].lerp(PHASE_COLORS[next_phase], progress)

func _phase_start_hour(phase: Phase) -> float:
	match phase:
		Phase.DAWN: return DAWN_START
		Phase.DAY: return DAY_START
		Phase.DUSK: return DUSK_START
		_: return NIGHT_START

func _phase_end_hour(phase: Phase) -> float:
	match phase:
		Phase.DAWN: return DAY_START
		Phase.DAY: return DUSK_START
		Phase.DUSK: return NIGHT_START
		_: return DAWN_START

func _next_phase(phase: Phase) -> Phase:
	match phase:
		Phase.DAWN: return Phase.DAY
		Phase.DAY: return Phase.DUSK
		Phase.DUSK: return Phase.NIGHT
		_: return Phase.DAWN

func _apply_ambient_color() -> void:
	if _canvas_modulate:
		_canvas_modulate.color = _current_ambient_color()

func is_night() -> bool:
	return current_phase == Phase.NIGHT

func is_dark() -> bool:
	return current_phase == Phase.NIGHT or current_phase == Phase.DUSK

## Hora do jogo formatada como "08:30".
func get_time_string() -> String:
	var hours := int(current_hour)
	var minutes := int((current_hour - hours) * 60.0)
	return "%02d:%02d" % [hours, minutes]

## Chave de tradução da fase atual, para ser passada a tr().
func get_phase_key() -> String:
	match current_phase:
		Phase.DAWN: return "PHASE_DAWN"
		Phase.DAY: return "PHASE_DAY"
		Phase.DUSK: return "PHASE_DUSK"
		_: return "PHASE_NIGHT"

func get_phase_name() -> String:
	return tr(get_phase_key())

## Progresso do dia atual (0.0 = 00:00, 1.0 = 24:00).
func get_day_progress() -> float:
	return current_hour / HOURS_PER_DAY

## Avança o tempo do jogo em `hours` horas (dormir, tratamentos longos).
func advance_hours(hours: float) -> void:
	var target := current_hour + hours
	while target >= HOURS_PER_DAY:
		target -= HOURS_PER_DAY
		day_number += 1
		new_day.emit(day_number)
	current_hour = target
	_check_phase_transition(current_hour)
	_apply_ambient_color()

func save_state() -> Dictionary:
	return {"current_hour": current_hour, "day_number": day_number}

func load_state(state: Dictionary) -> void:
	current_hour = state.get("current_hour", starting_hour)
	day_number = state.get("day_number", 1)
	current_phase = _phase_for_hour(current_hour)
	_last_reported_hour = int(current_hour)
	_apply_ambient_color()
