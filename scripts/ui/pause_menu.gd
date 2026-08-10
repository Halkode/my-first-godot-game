extends Control

## Menu de pausa do jogo (ESC). Dá acesso a salvar, configurações e
## voltar ao menu principal.
##
## Fica em PROCESS_MODE_ALWAYS para continuar respondendo enquanto a
## árvore está pausada.

const FADE_DURATION: float = 0.2

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _resume_button: Button = %ResumeButton
@onready var _save_button: Button = %SaveButton
@onready var _settings_button: Button = %SettingsButton
@onready var _menu_button: Button = %MainMenuButton
@onready var _settings_menu: Control = %SettingsMenu
@onready var _confirm_dialog: ConfirmationDialog = %ConfirmQuitDialog

var is_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_confirm_dialog.process_mode = Node.PROCESS_MODE_ALWAYS

	_resume_button.pressed.connect(close)
	_save_button.pressed.connect(_on_save_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_menu_button.pressed.connect(_on_main_menu_pressed)
	_confirm_dialog.confirmed.connect(_on_quit_confirmed)

	_settings_menu.hide()
	_settings_menu.closed.connect(_on_settings_closed)

	Localization.locale_changed.connect(_on_locale_changed)
	_refresh_texts()
	hide()

func _refresh_texts() -> void:
	_title.text = tr("PAUSE_TITLE")
	_resume_button.text = tr("MENU_RESUME")
	_save_button.text = tr("MENU_SAVE")
	_settings_button.text = tr("MENU_SETTINGS")
	_menu_button.text = tr("MENU_MAIN_MENU")
	_confirm_dialog.title = tr("CONFIRM_QUIT_TITLE")
	_confirm_dialog.dialog_text = tr("CONFIRM_QUIT_BODY")
	_confirm_dialog.ok_button_text = tr("CONFIRM_YES")
	_confirm_dialog.cancel_button_text = tr("CONFIRM_NO")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	## A tela de tratamento também usa ESC e tem prioridade quando aberta
	if TreatmentManager.is_open:
		return
	if _settings_menu.visible:
		return

	if is_open:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()

func open() -> void:
	if is_open:
		return
	is_open = true
	show()
	get_tree().paused = true

	modulate.a = 0.0
	_panel.scale = Vector2(0.96, 0.96)
	_panel.pivot_offset = _panel.size / 2.0

	var tween := create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(_panel, "scale", Vector2.ONE, FADE_DURATION)

	_resume_button.grab_focus()

func close() -> void:
	if not is_open:
		return
	is_open = false

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished

	hide()
	get_tree().paused = false

func _on_save_pressed() -> void:
	GameManager.save_game()
	UIManager.display_message(tr("MSG_SAVED"))

func _on_settings_pressed() -> void:
	_settings_menu.open()

func _on_settings_closed() -> void:
	_settings_button.grab_focus()

func _on_main_menu_pressed() -> void:
	_confirm_dialog.popup_centered()

func _on_quit_confirmed() -> void:
	is_open = false
	hide()
	## SceneManager despausa a árvore ao trocar de cena
	SceneManager.go_to_main_menu()

func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
