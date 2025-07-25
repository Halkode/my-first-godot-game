extends Node
signal memory_unlocked(memory_data: MemoryData)
signal narrative_event_triggered(event_name: String)
const MemoryData = preload("res://scripts/memory_data.gd")
# GameManager é um autoload e pode ser acessado diretamente

var memories: Array[MemoryData] = []
var discovered_memories: Array[String] = []
var narrative_flags: Dictionary = {}

func _ready() -> void:
	initialize_memories()

	# Conectar ao sinal de memórias descobertas do GameManager
	GameManager.memory_discovered.connect(_on_memory_discovered)

func initialize_memories() -> void:
	# Memórias relacionadas à narrativa do porão
	add_memory("memory_01", "O Despertar no Escuro",
		"A escuridão é a primeira coisa que você sente. Um cheiro de mofo e terra úmida. O frio penetra seus ossos. Você está deitado em um chão duro, sem lembranças de como chegou aqui. Uma sensação de vazio na mente e um pânico crescente no peito. Onde estou? Quem sou eu?",
		"", "")

	add_memory("memory_02", "A Presença Silenciosa",
		"Ao seu lado, uma forma inerte. Um corpo. O cheiro de morte é inconfundível agora, misturado ao mofo. Não há sinais de violência, apenas uma quietude perturbadora. O rosto está virado para longe, mas a silhueta é estranhamente familiar. Um arrepio percorre sua espinha. Seria... alguém que você conhecia?",
		"", "")

	add_memory("memory_03", "As Portas Seladas",
		"Você tateia na escuridão, encontrando paredes frias e úmidas. Há portas, mas todas estão trancadas, seladas. O desespero começa a se instalar. Não há saída aparente. A claustrofobia ameaça engoli-lo. A cada tentativa de abrir, a madeira range, mas não cede. Você está preso.",
		"", "")

	add_memory("memory_04", "O Ronco do Vazio",
		"A fome. Uma dor aguda no estômago que se intensifica a cada minuto. Seu corpo clama por sustento, mas não há nada à vista. A fraqueza começa a tomar conta, e a mente, já confusa, se torna ainda mais turva. Quanto tempo você pode durar sem comida?",
		"", "")

	add_memory("memory_05", "Ecos do Passado",
		"Cada objeto que você toca, cada sombra que dança na periferia da sua visão, parece carregar um eco. Fragmentos de imagens, sons distorcidos, sensações fugazes. São memórias? Ou apenas a mente pregando peças? A linha entre o real e o imaginado começa a se borrar.",
		"", "")

	add_memory("memory_06", "A Desintegração da Sanidade",
		"O tempo se torna um borrão. Dias e noites se misturam. A solidão e o confinamento corroem sua mente. Sussurros parecem vir das paredes, sombras se movem onde não há nada. A sanidade, um fio tênue, ameaça se romper. Você está perdendo o controle?",
		"", "")

	add_memory("memory_07", "Os Olhos na Escuridão",
		"Você não está sozinho. Há algo mais aqui, na escuridão. Não é humano. Seus olhos brilham, observando. O medo paralisa. Você tenta se esconder, mas sabe que não há para onde ir. O que são essas criaturas? E o que elas querem?",
		"", "")

	add_memory("memory_08", "A Chave Interior",
		"A fuga não é apenas física. É uma jornada para dentro de si mesmo. As ferramentas para escapar não são apenas objetos, mas as memórias que você precisa reconstruir. Sua identidade é a chave. Mas você está disposto a pagar o preço para se lembrar?",
		"", "")

	add_memory("memory_09", "Escolhas Amargas",
		"A cada passo, uma decisão. Cada escolha tem um peso, uma consequência. Você se depara com dilemas morais que testam seus limites. A linha entre o certo e o errado se desfaz na luta pela sobrevivência. Você fará o que for preciso para viver?",
		"", "")

	add_memory("memory_10", "A Conspiração Silenciosa",
		"A verdade se revela, fragmento por fragmento. Você não está aqui por acaso. Há uma razão, um propósito sombrio por trás do seu confinamento. Uma conspiração, um experimento, uma punição? O labirinto da sua mente se conecta a uma trama maior, mais sinistra do que você poderia imaginar.",
		"", "")

func add_memory(id: String, title: String, description: String, image_path: String, audio_path: String) -> void:
	var new_memory = MemoryData.new()
	new_memory.id = id
	new_memory.title = title
	new_memory.description = description
	new_memory.image_path = image_path
	new_memory.audio_path = audio_path
	memories.append(new_memory)

func unlock_memory(memory_id: String) -> void:
	if not discovered_memories.has(memory_id):
		discovered_memories.append(memory_id)
		var unlocked_data = get_memory_data(memory_id)
		if unlocked_data:
			emit_signal("memory_unlocked", unlocked_data)
			print("Memória desbloqueada: " + unlocked_data.title)
	else:
		print("Memória " + memory_id + " já foi desbloqueada.")

func get_memory_data(memory_id: String) -> MemoryData:
	for memory in memories:
		if memory.id == memory_id:
			return memory
	return null

func set_narrative_flag(flag_name: String, value: bool) -> void:
	narrative_flags[flag_name] = value
	print("Flag narrativa \'" + flag_name + "\' definida para " + str(value))

func get_narrative_flag(flag_name: String) -> bool:
	return narrative_flags.get(flag_name, false)

func trigger_narrative_event(event_name: String) -> void:
	emit_signal("narrative_event_triggered", event_name)
	print("Evento narrativo acionado: " + event_name)

func _on_memory_discovered(memory_id: String) -> void:
	unlock_memory(memory_id)

func get_discovered_memories() -> Array[MemoryData]:
	var unlocked_data_array: Array[MemoryData] = []
	for mem_id in discovered_memories:
		var data = get_memory_data(mem_id)
		if data:
			unlocked_data_array.append(data)
	return unlocked_data_array

func get_narrative_description() -> String:
	# Retorna uma descrição do estado narrativo atual com base nas memórias e flags
	var description = ""
	var unlocked_count = discovered_memories.size()
	
	if unlocked_count == 0:
		description = "Você acorda em um porão escuro, sem memórias, com fome, medo e frio."
	elif unlocked_count > 0 and unlocked_count < 5:
		description = "Fragmentos de memórias começam a surgir. O ambiente é hostil e a sanidade está em jogo."
	elif unlocked_count >= 5 and unlocked_count < 10:
		description = "A verdade sobre sua identidade e o que te trouxe aqui começa a se revelar. O perigo espreita."
	elif unlocked_count == 10:
		description = "Todas as memórias foram recuperadas. A chave para escapar está em suas mãos, mas o preço pode ser alto."
	
	return description
