class_name AudioManager
extends Node

@export var ambient_player: AudioStreamPlayer
@export var sfx_player: AudioStreamPlayer

func _ready() -> void:
	if not ambient_player:
		print("ERRO: Ambient AudioStreamPlayer não configurado.")
		return
	if not sfx_player:
		print("ERRO: SFX AudioStreamPlayer não configurado.")
		return

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


