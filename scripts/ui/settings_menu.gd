extends Control

## Painel de configurações: idioma, vídeo e áudio. Lê e escreve tudo
## através do autoload Settings, que persiste em user://settings.cfg.

signal closed

const FADE_DURATION: float = 0.25

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _language_label: Label = %LanguageLabel
@onready var _language_option: OptionButton = %LanguageOption
@onready var _display_label: Label = %DisplayLabel
@onready var _fullscreen_label: Label = %FullscreenLabel
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _vsync_label: Label = %VSyncLabel
@onready var _vsync_check: CheckButton = %VSyncCheck
@onready var _audio_label: Label = %AudioLabel
@onready var _master_label: Label = %MasterLabel
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_label: Label = %MusicLabel
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_label: Label = %SFXLabel
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton

## Evita que atualizar os controles a partir das configurações dispare
## os callbacks e reescreva o que acabou de ser lido.
var _syncing: bool = false

func _ready() -> void:
	## Precisa responder mesmo com a árvore pausada (menu de pausa)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_languages()
	_connect_controls()
	_refresh_texts()
	sync_from_settings()
	Localization.locale_changed.connect(_on_locale_changed)
	hide()

func _populate_languages() -> void:
	_language_option.clear()
	for i in Localization.SUPPORTED_LOCALES.size():
		var locale: String = Localization.SUPPORTED_LOCALES[i]
		_language_option.add_item(Localization.get_locale_name(locale), i)

func _connect_controls() -> void:
	_language_option.item_selected.connect(_on_language_selected)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_vsync_check.toggled.connect(_on_vsync_toggled)
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button.pressed.connect(close)

func _refresh_texts() -> void:
	_title.text = tr("SETTINGS_TITLE")
	_language_label.text = tr("SETTINGS_LANGUAGE")
	_display_label.text = tr("SETTINGS_DISPLAY")
	_fullscreen_label.text = tr("SETTINGS_FULLSCREEN")
	_vsync_label.text = tr("SETTINGS_VSYNC")
	_audio_label.text = tr("SETTINGS_AUDIO")
	_master_label.text = tr("SETTINGS_MASTER_VOLUME")
	_music_label.text = tr("SETTINGS_MUSIC_VOLUME")
	_sfx_label.text = tr("SETTINGS_SFX_VOLUME")
	_reset_button.text = tr("SETTINGS_RESET")
	_back_button.text = tr("MENU_BACK")

func sync_from_settings() -> void:
	_syncing = true

	var locale := String(Settings.get_value("locale"))
	var locale_index := Localization.SUPPORTED_LOCALES.find(locale)
	if locale_index != -1:
		_language_option.select(locale_index)

	_fullscreen_check.button_pressed = bool(Settings.get_value("fullscreen"))
	_vsync_check.button_pressed = bool(Settings.get_value("vsync"))
	_master_slider.value = float(Settings.get_value("master_volume"))
	_music_slider.value = float(Settings.get_value("music_volume"))
	_sfx_slider.value = float(Settings.get_value("sfx_volume"))

	_syncing = false

func open() -> void:
	sync_from_settings()
	show()
	modulate.a = 0.0
	_panel.scale = Vector2(0.96, 0.96)
	_panel.pivot_offset = _panel.size / 2.0

	var tween := create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(_panel, "scale", Vector2.ONE, FADE_DURATION)

	_back_button.grab_focus()

func close() -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_property(_panel, "scale", Vector2(0.96, 0.96), FADE_DURATION)
	await tween.finished

	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_language_selected(index: int) -> void:
	if _syncing:
		return
	Settings.set_value("locale", Localization.SUPPORTED_LOCALES[index])

func _on_fullscreen_toggled(pressed: bool) -> void:
	if not _syncing:
		Settings.set_value("fullscreen", pressed)

func _on_vsync_toggled(pressed: bool) -> void:
	if not _syncing:
		Settings.set_value("vsync", pressed)

func _on_master_changed(value: float) -> void:
	if not _syncing:
		Settings.set_value("master_volume", value)

func _on_music_changed(value: float) -> void:
	if not _syncing:
		Settings.set_value("music_volume", value)

func _on_sfx_changed(value: float) -> void:
	if not _syncing:
		Settings.set_value("sfx_volume", value)

func _on_reset_pressed() -> void:
	Settings.reset_to_defaults()
	sync_from_settings()

func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
