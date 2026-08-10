extends Node

## Autoload que guarda e aplica as preferências do jogador
## (idioma, vídeo e áudio) em user://settings.cfg.

signal settings_changed

const CONFIG_PATH := "user://settings.cfg"

## Buses de áudio criados em runtime caso o projeto ainda não os tenha,
## para que os sliders de música e efeitos funcionem separadamente.
const AUDIO_BUSES := ["Music", "SFX"]

const DEFAULTS := {
	"locale": "",  # vazio = detectar do sistema
	"fullscreen": false,
	"vsync": true,
	"master_volume": 0.8,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
}

var _values: Dictionary = DEFAULTS.duplicate()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	load_settings()
	apply_all()

## Garante que os buses Music e SFX existam, roteados para o Master.
func _ensure_audio_buses() -> void:
	for bus_name in AUDIO_BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var index := AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")

func get_value(key: String) -> Variant:
	return _values.get(key, DEFAULTS.get(key))

func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key):
		push_warning("Settings: chave desconhecida '%s'" % key)
		return
	if _values.get(key) == value:
		return
	_values[key] = value
	_apply_single(key)
	save_settings()
	settings_changed.emit()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		## Primeira execução: mantém os padrões e detecta o idioma.
		_values["locale"] = Localization.get_default_locale()
		save_settings()
		return

	for key in DEFAULTS:
		_values[key] = config.get_value("settings", key, DEFAULTS[key])

	if String(_values["locale"]).is_empty():
		_values["locale"] = Localization.get_default_locale()

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in _values:
		config.set_value("settings", key, _values[key])
	if config.save(CONFIG_PATH) != OK:
		push_warning("Settings: falha ao salvar %s" % CONFIG_PATH)

func apply_all() -> void:
	for key in _values:
		_apply_single(key)

func _apply_single(key: String) -> void:
	match key:
		"locale":
			Localization.set_locale(String(_values[key]))
		"fullscreen":
			var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if _values[key] \
				else DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(mode)
		"vsync":
			var vsync := DisplayServer.VSYNC_ENABLED if _values[key] \
				else DisplayServer.VSYNC_DISABLED
			DisplayServer.window_set_vsync_mode(vsync)
		"master_volume":
			_set_bus_volume("Master", _values[key])
		"music_volume":
			_set_bus_volume("Music", _values[key])
		"sfx_volume":
			_set_bus_volume("SFX", _values[key])

## Converte um volume linear de 0..1 para decibéis, silenciando o bus
## quando o slider chega a zero (linear_to_db(0) seria -inf).
func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	var volume := clampf(float(linear_volume), 0.0, 1.0)
	AudioServer.set_bus_mute(index, is_zero_approx(volume))
	if not is_zero_approx(volume):
		AudioServer.set_bus_volume_db(index, linear_to_db(volume))

func reset_to_defaults() -> void:
	_values = DEFAULTS.duplicate()
	_values["locale"] = Localization.get_default_locale()
	apply_all()
	save_settings()
	settings_changed.emit()
