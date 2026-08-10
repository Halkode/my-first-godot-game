class_name BandageMinigame
extends Control

## Minigame de aplicação de bandagem: o jogador precisa "enrolar" a
## bandagem segurando o botão do mouse e arrastando em círculo ao redor
## do membro ferido. A qualidade final depende da cobertura (ângulo
## total percorrido) e da uniformidade do movimento (poucas inversões
## de direção = enrolou de forma constante, não aleatória).

signal minigame_completed(quality: float)

const TARGET_ANGLE_DEGREES: float = 3.0 * 360.0
const TIME_LIMIT: float = 12.0

var _center: Vector2
var _radius: float = 90.0
var _dragging: bool = false
var _last_angle: float = 0.0
var _accumulated_angle: float = 0.0
var _direction_reversals: int = 0
var _last_direction_sign: int = 0
var _time_left: float = TIME_LIMIT
var _finished: bool = false

var _progress_bar: ProgressBar
var _timer_label: Label
var _instructions: Label
var _wrap_indicator: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func _build_ui() -> void:
	theme = preload("res://assets/ui/theme.tres")

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.position = Vector2(260, 80)
	root.custom_minimum_size = Vector2(360, 0)
	add_child(root)

	var title := Label.new()
	title.text = tr("BANDAGE_TITLE")
	root.add_child(title)

	_instructions = Label.new()
	_instructions.text = tr("BANDAGE_INSTRUCTIONS")
	_instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_instructions)

	_timer_label = Label.new()
	root.add_child(_timer_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.max_value = TARGET_ANGLE_DEGREES
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 16)
	_progress_bar.modulate = Color(0.3, 0.7, 0.95)
	root.add_child(_progress_bar)

	_wrap_indicator = Control.new()
	_wrap_indicator.custom_minimum_size = Vector2(220, 220)
	_wrap_indicator.draw.connect(_draw_wrap_indicator.bind(_wrap_indicator))
	root.add_child(_wrap_indicator)

	call_deferred("_update_center")

func _update_center() -> void:
	_center = _wrap_indicator.global_position + _wrap_indicator.size * 0.5

func _draw_wrap_indicator(indicator: Control) -> void:
	var local_center := indicator.size * 0.5
	indicator.draw_circle(local_center, _radius, Color(0.5, 0.35, 0.2, 0.6))
	indicator.draw_arc(local_center, _radius, 0, deg_to_rad(min(_accumulated_angle, TARGET_ANGLE_DEGREES)),
		32, Color(0.9, 0.9, 0.9), 6.0)

func reset(time_limit: float = TIME_LIMIT) -> void:
	_dragging = false
	_accumulated_angle = 0.0
	_direction_reversals = 0
	_last_direction_sign = 0
	_time_left = time_limit
	_finished = false
	if _progress_bar:
		_progress_bar.value = 0.0
	call_deferred("_update_center")

func _process(delta: float) -> void:
	if _finished or not visible:
		return
	_time_left -= delta
	_timer_label.text = Localization.tr_format(
		"BANDAGE_TIME", {"seconds": "%.1f" % maxf(_time_left, 0.0)}
	)
	if _wrap_indicator:
		_wrap_indicator.queue_redraw()
	if _time_left <= 0.0:
		_finish()

func _gui_input(event: InputEvent) -> void:
	if _finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_last_angle = (event.position - _local_center()).angle()
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var current_angle := (event.position - _local_center()).angle()
		var delta_angle := wrapf(current_angle - _last_angle, -PI, PI)
		_last_angle = current_angle

		var direction_sign := signi(roundi(sign(delta_angle)))
		if direction_sign != 0:
			if _last_direction_sign != 0 and direction_sign != _last_direction_sign:
				_direction_reversals += 1
			_last_direction_sign = direction_sign

		_accumulated_angle += abs(rad_to_deg(delta_angle))
		_progress_bar.value = min(_accumulated_angle, TARGET_ANGLE_DEGREES)

		if _accumulated_angle >= TARGET_ANGLE_DEGREES:
			_finish()

func _local_center() -> Vector2:
	return _wrap_indicator.position + _wrap_indicator.size * 0.5

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_dragging = false

	var coverage := clampf(_accumulated_angle / TARGET_ANGLE_DEGREES, 0.0, 1.0)
	## Cada inversão de direção penaliza levemente a uniformidade do enrolamento
	var uniformity := clampf(1.0 - float(_direction_reversals) * 0.08, 0.2, 1.0)
	var quality := clampf(coverage * uniformity, 0.0, 1.0)

	minigame_completed.emit(quality)
