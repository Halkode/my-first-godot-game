class_name NarrativeManager
extends Node

signal memory_unlocked(memory_data: MemoryData)
signal narrative_event_triggered(event_name: String)

@onready var game_manager: GameManager = get_node("/root/game_manager")

var memories: Array[MemoryData] = []
var discovered_memories: Array[String] = []
var narrative_flags: Dictionary = {}

func _ready() -> void:
	if not game_manager:
		print("ERRO: GameManager não encontrado para o NarrativeManager.")
	
	initialize_memories()
	
	# Conectar ao sinal de memórias descobertas do GameManager
	if game_manager:
		game_manager.memory_discovered.connect(_on_memory_discovered)

func initialize_memories() -> void:
	# Memórias relacionadas à narrativa do porão
	add_memory("memory_01", "Fragmento de Despertar", 
		"Você se lembra vagamente de ter acordado aqui... mas quando? Há quanto tempo está neste lugar?",
		"", "")
	
	add_memory("memory_02", "O Corpo ao Lado", 
		"Havia um corpo ao seu lado quando acordou. Quem era? Por que estava ali? A imagem está turva, mas o cheiro de morte permanece.",
		"Corpo", "Examinar")
	
	add_memory("memory_03", "Chaves Perdidas", 
		"Você se lembra de ter tido chaves... muitas chaves. Elas abriam portas importantes. Onde estão agora?",
		"Chave Enferrujada", "Pegar")
	
	add_memory("memory_04", "Fome Antiga", 
		"A fome não é nova. Você já sentiu isso antes, por dias... semanas? Quando foi a última vez que comeu algo de verdade?",
		"Comida Estragada", "Examinar")
	
	add_memory("memory_05", "Vozes no Escuro", 
		"Há vozes que ecoam nas paredes... ou são apenas ecos da sua própria mente fragmentada? Elas sussurram coisas que você prefere não entender.",
		"", "")
	
	add_memory("memory_06", "A Mesa Familiar", 
		"Esta mesa... você já se sentou aqui antes. Havia papéis, documentos importantes. Agora só resta poeira e esquecimento.",
		"Mesa Velha", "Examinar")
	
	add_memory("memory_07", "Luz da Vela", 
		"A luz da vela costumava ser sua única companhia nas noites longas. Ela dançava nas paredes, criando sombras que pareciam vivas.",
		"Vela", "Acender")
	
	add_memory("memory_08", "O Medo Crescente", 
		"O medo não era assim antes. Ele cresceu, se alimentou da sua sanidade, se tornou uma entidade própria que habita este lugar.",
		"", "")
	
	add_memory("memory_09", "Identidade Perdida", 
		"Quem você era antes de acordar aqui? O espelho reflete um rosto que você mal reconhece. Será mesmo o seu?",
		"Espelho Quebrado", "Examinar")
	
	add_memory("memory_10", "A Verdade Final", 
		"Talvez... talvez você não esteja preso aqui por acaso. Talvez você pertença a este lugar. Talvez sempre tenha pertencido.",
		"", "")

func add_memory(id: String, title: String, text: String, item_name: String = "", action: String = "") -> void:
	var memory = MemoryData.new(id, title, text, item_name, action)
	memories.append(memory)

func discover_memory(memory_id: String) -> bool:
	if memory_id in discovered_memories:
		return false # Já descoberta
	
	var memory = get_memory_by_id(memory_id)
	if memory:
		discovered_memories.append(memory_id)
		memory_unlocked.emit(memory)
		
		# Registrar no GameManager também
		if game_manager:
			game_manager.discover_memory(memory_id)
		
		print("Memória desbloqueada: ", memory.title)
		return true
	
	return false

func get_memory_by_id(id: String) -> MemoryData:
	for memory in memories:
		if memory.id == id:
			return memory
	return null

func get_memory_by_item_and_action(item_name: String, action: String) -> MemoryData:
	for memory in memories:
		if memory.associated_item_name == item_name and memory.triggered_by_action == action:
			return memory
	return null

func trigger_memory_by_item(item_name: String, action: String) -> bool:
	var memory = get_memory_by_item_and_action(item_name, action)
	if memory and memory.id not in discovered_memories:
		return discover_memory(memory.id)
	return false

func set_narrative_flag(flag_name: String, value: bool) -> void:
	narrative_flags[flag_name] = value
	narrative_event_triggered.emit(flag_name)
	print("Narrative flag set: ", flag_name, " = ", value)

func get_narrative_flag(flag_name: String) -> bool:
	return narrative_flags.get(flag_name, false)

func get_discovered_memories() -> Array[MemoryData]:
	var discovered: Array[MemoryData] = []
	for memory in memories:
		if memory.id in discovered_memories:
			discovered.append(memory)
	return discovered

func get_memory_progress() -> float:
	return float(discovered_memories.size()) / float(memories.size())

func _on_memory_discovered(memory_id: String) -> void:
	# Callback quando uma memória é descoberta via GameManager
	var memory = get_memory_by_id(memory_id)
	if memory:
		print("NarrativeManager: Memória descoberta - ", memory.title)
		
		# Verificar se descobrir esta memória desbloqueia eventos narrativos
		check_narrative_triggers(memory_id)

func check_narrative_triggers(memory_id: String) -> void:
	# Verificar se certas combinações de memórias desbloqueiam eventos
	match memory_id:
		"memory_02":
			set_narrative_flag("body_examined", true)
		"memory_05":
			if get_narrative_flag("body_examined"):
				set_narrative_flag("voices_and_death_connected", true)
				game_manager.display_message("As vozes parecem mais claras agora... elas falam sobre o corpo.")
		"memory_09":
			set_narrative_flag("identity_questioned", true)
			if discovered_memories.size() >= 7:
				set_narrative_flag("near_truth", true)
				game_manager.display_message("Você está começando a entender a verdade sobre este lugar...")
		"memory_10":
			set_narrative_flag("truth_revealed", true)
			game_manager.display_message("A verdade é mais terrível do que você imaginava...")

func get_current_narrative_state() -> String:
	var discovered_count = discovered_memories.size()
	
	if discovered_count == 0:
		return "awakening"
	elif discovered_count <= 3:
		return "confusion"
	elif discovered_count <= 6:
		return "realization"
	elif discovered_count <= 9:
		return "horror"
	else:
		return "acceptance"

func get_narrative_description() -> String:
	match get_current_narrative_state():
		"awakening":
			return "Você acabou de despertar neste lugar sombrio. Tudo é confuso e assustador."
		"confusion":
			return "Fragmentos de memória começam a retornar, mas ainda não fazem sentido completo."
		"realization":
			return "As peças do quebra-cabeça começam a se encaixar. A verdade está próxima."
		"horror":
			return "Você está começando a entender o que realmente aconteceu. O horror se intensifica."
		"acceptance":
			return "A verdade foi revelada. Agora você deve decidir o que fazer com esse conhecimento."
		_:
			return "Estado narrativo desconhecido."

