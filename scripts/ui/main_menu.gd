extends Control

## Tela inicial: fundo animado, título, botões e acesso às
## configurações. As animações usam Tween (a forma idiomática no
## Godot 4) em vez de AnimationPlayer, já que são transições simples
## e criadas em runtime.

const STAGGER_DELAY: float = 0.08
const ENTRANCE_DURATION: float = 0.5
const HOVER_SCALE: float = 1.04

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _buttons: VBoxContainer = %Buttons
@onready var _new_game_button: Button = %NewGameButton
@onready var _continue_button: Button = %ContinueButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_menu: Control = %SettingsMenu
@onready var _confirm_dialog: ConfirmationDialog = %ConfirmNewGameDialog
@onready var _version_label: Label = %VersionLabel

func _ready() -> void:
	_connect_buttons()
	_refresh_texts()
	Localization.locale_changed.connect(_on_locale_changed)

	_settings_menu.hide()
	_settings_menu.closed.connect(_on_settings_closed)

	_animate_entrance()

func _connect_buttons() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_confirm_dialog.confirmed.connect(_start_new_game)

	## Feedback de hover/foco em todos os botões do menu
	for button in [_new_game_button, _continue_button, _settings_button, _quit_button]:
		button.pivot_offset = button.size / 2.0
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.mouse_exited.connect(_on_button_unhovered.bind(button))
		button.focus_entered.connect(_on_button_hovered.bind(button))
		button.focus_exited.connect(_on_button_unhovered.bind(button))

func _refresh_texts() -> void:
	_title.text = tr("GAME_TITLE")
	_subtitle.text = tr("GAME_SUBTITLE")
	_new_game_button.text = tr("MENU_NEW_GAME")
	_continue_button.text = tr("MENU_CONTINUE")
	_settings_button.text = tr("MENU_SETTINGS")
	_quit_button.text = tr("MENU_QUIT")
	_confirm_dialog.title = tr("CONFIRM_NEW_GAME_TITLE")
	_confirm_dialog.dialog_text = tr("CONFIRM_NEW_GAME_BODY")
	_confirm_dialog.ok_button_text = tr("CONFIRM_YES")
	_confirm_dialog.cancel_button_text = tr("CONFIRM_NO")
	_version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.1.0")

	## "Carregar jogo" só faz sentido se existir um save
	_continue_button.disabled = not _has_save_file()

func _has_save_file() -> bool:
	return FileAccess.file_exists("user://savegame.dat")

## Entrada escalonada: título primeiro, botões em cascata logo depois.
func _animate_entrance() -> void:
	var elements: Array[Control] = [_title, _subtitle]
	elements.append_array(_buttons.get_children())

	for i in elements.size():
		var element := elements[i]
		element.modulate.a = 0.0
		element.position.y += 12.0

		var tween := create_tween().set_parallel(true)
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(element, "modulate:a", 1.0, ENTRANCE_DURATION) \
			.set_delay(i * STAGGER_DELAY)
		tween.tween_property(element, "position:y", element.position.y - 12.0, ENTRANCE_DURATION) \
			.set_delay(i * STAGGER_DELAY)

func _on_button_hovered(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), 0.15)

func _on_button_unhovered(button: Button) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2.ONE, 0.15)

func _on_new_game_pressed() -> void:
	## Só pede confirmação se houver progresso a perder
	if _has_save_file():
		_confirm_dialog.popup_centered()
	else:
		_start_new_game()

func _start_new_game() -> void:
	SceneManager.start_new_game()

func _on_continue_pressed() -> void:
	SceneManager.continue_game()

func _on_settings_pressed() -> void:
	_settings_menu.open()

func _on_settings_closed() -> void:
	_settings_button.grab_focus()

func _on_quit_pressed() -> void:
	SceneManager.quit_game()

func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
