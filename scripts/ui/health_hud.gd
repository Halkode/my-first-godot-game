class_name HealthHUD
extends CanvasLayer

## HUD de jogo: vida, sangramento, dor e relógio do ciclo dia/noite.
##
## Fica oculto por padrão e só aparece quando um Player entra na cena
## (ver HealthManager.set_hud_visible), para não cobrir o menu inicial.

const THEME := preload("res://assets/ui/theme.tres")

const FADE_DURATION: float = 0.3
## Abaixo desta fração de vida o painel começa a pulsar
const CRITICAL_HEALTH_RATIO: float = 0.3

var _root: Control
var _panel: PanelContainer
var _hp_bar: ProgressBar
var _hp_label: Label
var _bleeding_label: Label
var _pain_bar: ProgressBar
var _clock_label: Label

var _critical_tween: Tween
var _clock_accumulator: float = 0.0

func _ready() -> void:
	layer = 10
	_build_ui()
	_connect_signals()
	_refresh_all()
	visible = false

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = THEME
	add_child(_root)

	_panel = PanelContainer.new()
	_panel.position = Vector2(16, 16)
	_panel.custom_minimum_size = Vector2(210, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	_panel.add_child(layout)

	_clock_label = Label.new()
	_clock_label.add_theme_color_override("font_color", Color(0.72, 0.6, 0.35))
	_clock_label.add_theme_font_size_override("font_size", 13)
	layout.add_child(_clock_label)

	layout.add_child(HSeparator.new())

	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 13)
	layout.add_child(_hp_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(0, 12)
	layout.add_child(_hp_bar)

	_bleeding_label = Label.new()
	_bleeding_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
	_bleeding_label.add_theme_font_size_override("font_size", 12)
	_bleeding_label.visible = false
	layout.add_child(_bleeding_label)

	var pain_label := Label.new()
	pain_label.add_theme_font_size_override("font_size", 13)
	pain_label.text = tr("HUD_PAIN")
	layout.add_child(pain_label)

	_pain_bar = ProgressBar.new()
	_pain_bar.max_value = 1.0
	_pain_bar.value = 0.0
	_pain_bar.show_percentage = false
	_pain_bar.custom_minimum_size = Vector2(0, 7)
	## Dor usa âmbar para não competir visualmente com a barra de vida
	_pain_bar.self_modulate = Color(1.4, 1.1, 0.45)
	layout.add_child(_pain_bar)

func _connect_signals() -> void:
	HealthManager.health_changed.connect(_on_health_changed)
	HealthManager.bleeding_changed.connect(_on_bleeding_changed)
	HealthManager.pain_changed.connect(_on_pain_changed)
	Localization.locale_changed.connect(_on_locale_changed)

func _refresh_all() -> void:
	_on_health_changed(HealthManager.current_health, HealthManager.max_health)
	_on_bleeding_changed(HealthManager.get_total_bleeding())
	_on_pain_changed(HealthManager.get_total_pain())
	_update_clock()

## Fade suave em vez de aparecer/sumir de uma vez.
func set_hud_visible(should_show: bool) -> void:
	if should_show == visible:
		return

	if should_show:
		visible = true
		_root.modulate.a = 0.0
		_refresh_all()
		var tween := create_tween()
		tween.tween_property(_root, "modulate:a", 1.0, FADE_DURATION)
		return

	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	## O relógio só muda de minuto a cada ~1s real, atualizar por frame
	## seria desperdício de layout.
	_clock_accumulator += delta
	if _clock_accumulator >= 0.5:
		_clock_accumulator = 0.0
		_update_clock()

func _update_clock() -> void:
	_clock_label.text = "%s %d — %s · %s" % [
		tr("HUD_DAY"),
		DayNightCycle.day_number,
		DayNightCycle.get_time_string(),
		tr(DayNightCycle.get_phase_key()),
	]

func _on_health_changed(current: float, maximum: float) -> void:
	_hp_bar.max_value = maximum
	_hp_label.text = "%s  %d / %d" % [tr("HUD_HEALTH"), roundi(current), roundi(maximum)]

	## Anima a barra em vez de saltar, para o dano ser legível
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_hp_bar, "value", current, 0.25)

	_update_critical_pulse(current / maxf(maximum, 1.0))

## Pulso lento no painel quando a vida está crítica.
func _update_critical_pulse(health_ratio: float) -> void:
	var should_pulse := health_ratio <= CRITICAL_HEALTH_RATIO and health_ratio > 0.0

	if not should_pulse:
		if _critical_tween:
			_critical_tween.kill()
			_critical_tween = null
			_panel.modulate = Color.WHITE
		return

	if _critical_tween:
		return

	_critical_tween = create_tween().set_loops()
	_critical_tween.set_trans(Tween.TRANS_SINE)
	_critical_tween.tween_property(_panel, "modulate", Color(1.25, 0.8, 0.8), 0.6)
	_critical_tween.tween_property(_panel, "modulate", Color.WHITE, 0.6)

func _on_bleeding_changed(total_bleeding: float) -> void:
	var is_bleeding := total_bleeding > 0.0
	_bleeding_label.visible = is_bleeding
	if is_bleeding:
		_bleeding_label.text = "%s (-%.1f HP/s)" % [tr("HUD_BLEEDING"), total_bleeding]

func _on_pain_changed(total_pain: float) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_pain_bar, "value", total_pain, 0.25)

func _on_locale_changed(_locale: String) -> void:
	_refresh_all()

# Debug (apenas em builds de desenvolvimento): F1 aplica um corte
# profundo no braço direito, F2 dá uma bandagem.
func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			HealthManager.add_injury(
				BodyPart.Id.ARM_RIGHT, Injury.create(Injury.Type.CUT_DEEP, 0.7)
			)
		elif event.keycode == KEY_F2:
			InventoryManager.add_item({"name": "Bandagem", "description": tr("ITEM_BANDAGE")})
