extends Node

var ambient_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	# Obter referências aos AudioStreamPlayers na cena principal
	# Assumindo que eles estão em /root/main/AudioManager/AmbientPlayer e /root/main/AudioManager/SFXPlayer
	# ou que o AudioManager é um nó na cena e eles são seus filhos.
	# Como AudioManager é um autoload, eles precisam ser referenciados a partir da cena principal.
	
	# É melhor que esses players sejam filhos do AudioManager se ele for um nó na cena.
	# Se AudioManager é um autoload, ele não terá filhos na cena. 
	# A abordagem mais robusta para autoloads é que eles gerenciem seus próprios players, 
	# ou que os players sejam passados a eles de alguma forma.
	# Por simplicidade, vamos assumir que eles são filhos de um nó AudioManager na cena principal.
	# No entanto, o `main.tscn` mostra que eles são filhos do `AudioManager` que é um nó na cena, 
	# e o `AudioManager` é um autoload. Isso é uma contradição. 
	# A solução é remover o `AudioManager` da cena `main.tscn` e deixar ele ser *apenas* um autoload.
	# Se ele é um autoload, ele não pode ter `@onready` de nós da cena. 
	# Ele precisa criar e gerenciar seus próprios `AudioStreamPlayer`s ou recebê-los.
	
	# Vamos mudar a abordagem: o AudioManager será *apenas* um autoload e terá seus próprios players.
	ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	print("AudioManager ready. AmbientPlayer and SFXPlayer created.")

func play_ambient_sound(audio_stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if ambient_player:
		ambient_player.stream = audio_stream
		ambient_player.volume_db = volume_db
		ambient_player.pitch_scale = pitch_scale
		ambient_player.play()
		print("Tocando som ambiente.")

func stop_ambient_sound() -> void:
	if ambient_player:
		ambient_player.stop()
		print("Parando som ambiente.")

func play_sfx(audio_stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if sfx_player:
		sfx_player.stream = audio_stream
		sfx_player.volume_db = volume_db
		sfx_player.pitch_scale = pitch_scale
		sfx_player.play()
		print("Tocando SFX.")

func set_ambient_volume(volume_db: float) -> void:
	if ambient_player:
		ambient_player.volume_db = volume_db

func set_sfx_volume(volume_db: float) -> void:
	if sfx_player:
		sfx_player.volume_db = volume_db

func _on_fear_changed(new_fear: float) -> void:
	# Exemplo: Aumentar o volume de sons de medo com base no nível de medo
	var fear_volume = linear_to_db(new_fear / GameManager.max_fear) * 5 # Ajuste o multiplicador conforme necessário
	set_sfx_volume(fear_volume)
	print("Volume SFX ajustado devido ao medo: ", fear_volume)

func _on_sanity_changed(new_sanity: float) -> void:
	# Exemplo: Reduzir o volume ambiente se a sanidade estiver muito baixa
	if new_sanity < 20:
		set_ambient_volume(-20) # Reduz o volume ambiente
	else:
		set_ambient_volume(0) # Volta ao normal
	print("Volume ambiente ajustado devido à sanidade: ", new_sanity)
