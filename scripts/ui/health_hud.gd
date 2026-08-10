class_name HealthHUD
extends CanvasLayer

## HUD simples de saúde: HP total, sangramento e dor, além do
## relógio do ciclo dia/noite.
## Construído em código e instanciado pelo HealthManager.

var _hp_bar: ProgressBar
var _hp_label: Label
var _bleeding_label: Label
var _pain_bar: ProgressBar
var _clock_label: Label

func _ready() -> void:
	layer = 10
	_build_ui()
	HealthManager.health_changed.connect(_on_health_changed)
	HealthManager.bleeding_changed.connect(_on_bleeding_changed)
	HealthManager.pain_changed.connect(_on_pain_changed)
	_on_health_changed(HealthManager.current_health, HealthManager.max_health)
	_on_bleeding_changed(HealthManager.get_total_bleeding())
	_on_pain_changed(HealthManager.get_total_pain())

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(10, 10)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(180, 0)
	panel.add_child(vbox)

	_clock_label = Label.new()
	_clock_label.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
	vbox.add_child(_clock_label)

	_hp_label = Label.new()
	_hp_label.text = "HP: 100 / 100"
	vbox.add_child(_hp_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(0, 14)
	_hp_bar.modulate = Color(0.85, 0.2, 0.2)
	vbox.add_child(_hp_bar)

	_bleeding_label = Label.new()
	_bleeding_label.text = ""
	_bleeding_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	vbox.add_child(_bleeding_label)

	var pain_label := Label.new()
	pain_label.text = "Dor"
	vbox.add_child(pain_label)

	_pain_bar = ProgressBar.new()
	_pain_bar.max_value = 1.0
	_pain_bar.value = 0.0
	_pain_bar.show_percentage = false
	_pain_bar.custom_minimum_size = Vector2(0, 8)
	_pain_bar.modulate = Color(0.9, 0.7, 0.2)
	vbox.add_child(_pain_bar)

func _on_health_changed(current: float, maximum: float) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_label.text = "HP: %d / %d" % [roundi(current), roundi(maximum)]

func _on_bleeding_changed(total_bleeding: float) -> void:
	if total_bleeding > 0.0:
		_bleeding_label.text = "Sangrando (-%.1f HP/s)" % total_bleeding
	else:
		_bleeding_label.text = ""

func _on_pain_changed(total_pain: float) -> void:
	_pain_bar.value = total_pain

func _process(_delta: float) -> void:
	_clock_label.text = "Dia %d — %s (%s)" % [
		DayNightCycle.day_number,
		DayNightCycle.get_time_string(),
		DayNightCycle.get_phase_name(),
	]

# Debug (apenas em builds de desenvolvimento): F1 aplica um corte profundo
# no braço direito para testar sangramento, dor e HUD.
func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			var injury := Injury.create(Injury.Type.CUT_DEEP, 0.7)
			HealthManager.add_injury(BodyPart.Id.ARM_RIGHT, injury)
		elif event.keycode == KEY_F2:
			InventoryManager.add_item({"name": "Bandagem", "description": "Usada para estancar sangramentos."})
