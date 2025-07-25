extends Node

signal day_started
signal night_started

@export var day_duration_seconds: float = 300.0  # 5 minutos de dia
@export var night_duration_seconds: float = 300.0 # 5 minutos de noite

var current_time_of_day: float = 0.0 # 0.0 = início do dia, 1.0 = início da noite
var is_day: bool = true

# GameManager é um autoload e pode ser acessado diretamente

func _ready() -> void:
	start_day()

func _process(delta: float) -> void:
	current_time_of_day += delta
	
	if is_day:
		if current_time_of_day >= day_duration_seconds:
			start_night()
	else:
		if current_time_of_day >= night_duration_seconds:
			start_day()
	
	# Atualizar o GameManager com o estado do dia/noite
	GameManager.is_night = not is_day

func start_day() -> void:
	is_day = true
	current_time_of_day = 0.0
	day_started.emit()
	print("O dia começou!")
	# Lógica para ajustar a iluminação global, etc.
	# Exemplo: LightingSystem.set_global_light_intensity(1.0)

func start_night() -> void:
	is_day = false
	current_time_of_day = 0.0
	night_started.emit()
	print("A noite começou!")
	# Lógica para ajustar a iluminação global, etc.
	# Exemplo: LightingSystem.set_global_light_intensity(0.2)

func get_time_of_day_progress() -> float:
	if is_day:
		return current_time_of_day / day_duration_seconds
	else:
		return current_time_of_day / night_duration_seconds

func get_current_time_string() -> String:
	var total_seconds = current_time_of_day
	var minutes = int(total_seconds / 60)
	var seconds = int(fmod(total_seconds, 60))
	return "%02d:%02d" % [minutes, seconds]
