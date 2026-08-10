extends Node

## Autoload que carrega assets/locale/translations.csv em runtime e
## registra um Translation por idioma no TranslationServer.
##
## O Godot também sabe importar CSVs de tradução pelo editor, gerando
## arquivos .translation. Fazemos o registro em runtime para que as
## traduções funcionem mesmo sem esse passo de importação, e para que
## adicionar uma coluna no CSV baste para adicionar um idioma.

signal locale_changed(locale: String)

const CSV_PATH := "res://assets/locale/translations.csv"

## Idiomas oferecidos no menu, na ordem em que aparecem.
const SUPPORTED_LOCALES := ["pt_BR", "en", "es"]

const LOCALE_NAMES := {
	"pt_BR": "Português (Brasil)",
	"en": "English",
	"es": "Español",
}

var _loaded: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_translations()

func _load_translations() -> void:
	if _loaded:
		return

	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if not file:
		push_error("Localization: não foi possível abrir %s" % CSV_PATH)
		return

	var header := file.get_csv_line()
	if header.size() < 2:
		push_error("Localization: CSV sem colunas de idioma.")
		return

	## Coluna 0 é a chave; as demais são os idiomas.
	var translations: Array[Translation] = []
	for i in range(1, header.size()):
		var translation := Translation.new()
		translation.locale = header[i].strip_edges()
		translations.append(translation)

	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or row[0].strip_edges().is_empty():
			continue
		var key := row[0].strip_edges()
		for i in range(1, mini(row.size(), header.size())):
			translations[i - 1].add_message(key, row[i])

	file.close()

	for translation in translations:
		TranslationServer.add_translation(translation)

	_loaded = true
	print("Localization: %d idiomas carregados." % translations.size())

func set_locale(locale: String) -> void:
	if not SUPPORTED_LOCALES.has(locale):
		push_warning("Localization: idioma não suportado: %s" % locale)
		return
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)

func get_locale() -> String:
	return TranslationServer.get_locale()

func get_locale_name(locale: String) -> String:
	return LOCALE_NAMES.get(locale, locale)

## Idioma do sistema, se estiver entre os suportados; senão pt_BR.
func get_default_locale() -> String:
	var system_locale := OS.get_locale()
	if SUPPORTED_LOCALES.has(system_locale):
		return system_locale

	## OS.get_locale() devolve algo como "en_US"; tenta só o idioma.
	var language := system_locale.split("_")[0]
	for locale in SUPPORTED_LOCALES:
		if locale.begins_with(language):
			return locale
	return "pt_BR"

## Traduz uma chave e substitui placeholders no formato {nome}.
func tr_format(key: String, values: Dictionary) -> String:
	return tr(key).format(values)
