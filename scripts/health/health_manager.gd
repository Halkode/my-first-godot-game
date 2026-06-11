extends Node

## Autoload que gerencia o estado de saúde do jogador:
## partes do corpo, ferimentos, HP, sangramento e dor.
## Efeitos contínuos rodam em ticks de 1 segundo (não por frame).

signal injury_added(part: BodyPart, injury: Injury)
signal injury_removed(part: BodyPart, injury: Injury)
signal health_changed(current: float, maximum: float)
signal bleeding_changed(total_bleeding: float)
signal pain_changed(total_pain: float)
signal player_died

const TICK_INTERVAL: float = 1.0
## Dor acima deste valor começa a reduzir a velocidade do jogador
const PAIN_SPEED_THRESHOLD: float = 0.2
## Redução máxima de velocidade causada por dor (50%)
const PAIN_MAX_SPEED_PENALTY: float = 0.5

@export var max_health: float = 100.0

var current_health: float = 100.0
var body_parts: Array[BodyPart] = []

const HealthHUDScene := preload("res://scripts/ui/health_hud.gd")

var _tick_timer: Timer
var _hud: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_body_parts()
	_setup_tick_timer()
	_spawn_hud.call_deferred()

func _spawn_hud() -> void:
	_hud = HealthHUDScene.new()
	add_child(_hud)

func _setup_body_parts() -> void:
	body_parts.clear()
	for part_id in [
		BodyPart.Id.HEAD,
		BodyPart.Id.TORSO,
		BodyPart.Id.ARM_LEFT,
		BodyPart.Id.ARM_RIGHT,
		BodyPart.Id.LEG_LEFT,
		BodyPart.Id.LEG_RIGHT,
	]:
		var part := BodyPart.new()
		part.id = part_id
		body_parts.append(part)

func _setup_tick_timer() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = TICK_INTERVAL
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)

func get_body_part(part_id: BodyPart.Id) -> BodyPart:
	for part in body_parts:
		if part.id == part_id:
			return part
	return null

func add_injury(part_id: BodyPart.Id, injury: Injury) -> void:
	var part := get_body_part(part_id)
	if not part:
		push_warning("HealthManager: parte do corpo inválida: %s" % part_id)
		return
	part.add_injury(injury)
	injury_added.emit(part, injury)
	bleeding_changed.emit(get_total_bleeding())
	pain_changed.emit(get_total_pain())
	if UIManager and UIManager.has_method("display_message"):
		UIManager.display_message("%s: %s!" % [part.get_part_name(), injury.get_type_name()])

func remove_injury(part_id: BodyPart.Id, injury: Injury) -> void:
	var part := get_body_part(part_id)
	if not part:
		return
	part.remove_injury(injury)
	injury_removed.emit(part, injury)
	bleeding_changed.emit(get_total_bleeding())
	pain_changed.emit(get_total_pain())

func get_total_bleeding() -> float:
	var total := 0.0
	for part in body_parts:
		total += part.get_total_bleeding()
	return total

func get_total_pain() -> float:
	var total := 0.0
	for part in body_parts:
		total += part.get_total_pain()
	return clampf(total, 0.0, 1.0)

## Multiplicador de velocidade do jogador (1.0 = normal).
## Dor acima do limiar reduz a velocidade até PAIN_MAX_SPEED_PENALTY.
func get_speed_multiplier() -> float:
	var pain := get_total_pain()
	if pain <= PAIN_SPEED_THRESHOLD:
		return 1.0
	var excess := (pain - PAIN_SPEED_THRESHOLD) / (1.0 - PAIN_SPEED_THRESHOLD)
	return 1.0 - excess * PAIN_MAX_SPEED_PENALTY

func modify_health(amount: float) -> void:
	current_health = clampf(current_health + amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		player_died.emit()

func _on_tick() -> void:
	var bleeding := get_total_bleeding()
	if bleeding > 0.0:
		modify_health(-bleeding * TICK_INTERVAL)

func reset() -> void:
	current_health = max_health
	_setup_body_parts()
	health_changed.emit(current_health, max_health)
	bleeding_changed.emit(0.0)
	pain_changed.emit(0.0)
