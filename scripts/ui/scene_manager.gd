extends Node

## Autoload responsável por trocar de cena com um fade, evitando o
## corte seco de change_scene_to_file().
##
## O overlay vive numa CanvasLayer própria com layer alto, então ele
## cobre qualquer HUD durante a transição.

signal transition_started
signal transition_finished

const FADE_DURATION: float = 0.4

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const GAME_SCENE := "res://scenes/main.tscn"

var _overlay: ColorRect
var _is_transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	## Não intercepta cliques quando está invisível
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	_overlay.visible = false
	layer.add_child(_overlay)

func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	transition_started.emit()

	await fade_out()

	## O jogo pode estar pausado (tela de tratamento, menu); a nova cena
	## precisa começar despausada.
	get_tree().paused = false

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneManager: falha ao carregar %s (erro %d)" % [scene_path, error])

	## Espera a nova cena entrar na árvore antes de revelar.
	await get_tree().process_frame

	await fade_in()

	_is_transitioning = false
	transition_finished.emit()

func fade_out() -> void:
	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished

func fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func go_to_main_menu() -> void:
	change_scene(MAIN_MENU)

func start_new_game() -> void:
	GameManager.reset_game()
	HealthManager.reset()
	change_scene(GAME_SCENE)

func continue_game() -> void:
	if not GameManager.load_game():
		push_warning("SceneManager: não há jogo salvo para carregar.")
		return
	change_scene(GAME_SCENE)

func quit_game() -> void:
	await fade_out()
	get_tree().quit()
