class_name TreatmentScreen
extends Control

## Tela de tratamento: lista partes do corpo do jogador e seus
## ferimentos, permitindo aplicar um item de tratamento disponível.
## Pausa o jogo enquanto aberta (ver TreatmentManager.open_screen).

var _body_part_list: VBoxContainer
var _injury_panel: VBoxContainer
var _selected_part: BodyPart

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()

func _build_ui() -> void:
	theme = preload("res://assets/ui/theme.tres")

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.position = Vector2(260, 80)
	root.custom_minimum_size = Vector2(480, 0)
	add_child(root)

	var title := Label.new()
	title.text = tr("TREATMENT_TITLE")
	title.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(title)

	var columns := HBoxContainer.new()
	root.add_child(columns)

	_body_part_list = VBoxContainer.new()
	_body_part_list.custom_minimum_size = Vector2(180, 0)
	columns.add_child(_body_part_list)

	_injury_panel = VBoxContainer.new()
	_injury_panel.custom_minimum_size = Vector2(280, 0)
	columns.add_child(_injury_panel)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		TreatmentManager.close_screen()
		get_viewport().set_input_as_handled()

func refresh() -> void:
	_selected_part = null
	_rebuild_body_part_list()
	_rebuild_injury_panel()

func _rebuild_body_part_list() -> void:
	for child in _body_part_list.get_children():
		child.queue_free()

	for part in HealthManager.body_parts:
		var button := Button.new()
		var suffix := " (%d)" % part.injuries.size() if part.has_injuries() else ""
		button.text = part.get_part_name() + suffix
		button.disabled = not part.has_injuries()
		button.pressed.connect(_on_part_selected.bind(part))
		_body_part_list.add_child(button)

func _on_part_selected(part: BodyPart) -> void:
	_selected_part = part
	_rebuild_injury_panel()

func _rebuild_injury_panel() -> void:
	for child in _injury_panel.get_children():
		child.queue_free()

	if not _selected_part:
		var hint := Label.new()
		hint.text = tr("TREATMENT_SELECT_PART")
		_injury_panel.add_child(hint)
		return

	var available_items := TreatmentManager.get_available_treatment_items()

	for injury in _selected_part.injuries:
		var row := VBoxContainer.new()
		_injury_panel.add_child(row)

		var label := Label.new()
		var status := Localization.tr_format(
			"TREATMENT_TREATED", {"quality": roundi(injury.treatment_quality * 100)}
		) if injury.treated else tr("TREATMENT_UNTREATED")
		label.text = "%s — %s" % [injury.get_type_name(), status]
		row.add_child(label)

		if injury.treated:
			continue

		if available_items.is_empty():
			var no_item_label := Label.new()
			no_item_label.text = tr("TREATMENT_NO_ITEMS")
			row.add_child(no_item_label)
			continue

		for item_name in available_items:
			var treat_button := Button.new()
			treat_button.text = Localization.tr_format("TREATMENT_USE_ITEM", {"item": item_name})
			treat_button.pressed.connect(_on_treat_pressed.bind(_selected_part, injury, item_name))
			row.add_child(treat_button)

func _on_treat_pressed(part: BodyPart, injury: Injury, item_name: String) -> void:
	## A UI é reconstruída pelo TreatmentManager via refresh() quando o
	## tratamento (e o minigame, se houver) for concluído.
	TreatmentManager.apply_treatment(part, injury, item_name)
