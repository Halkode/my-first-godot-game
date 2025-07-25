class_name CombatSystem
extends Node

signal entity_damaged(entity: Node, damage: float)
signal entity_died(entity: Node)

@onready var game_manager: GameManager = get_node("/root/game_manager")

func _ready() -> void:
	if not game_manager:
		print("ERRO: GameManager não encontrado para o CombatSystem.")

func attack(attacker: Node, target: Node, damage_amount: float) -> void:
	if not target.has_method("take_damage"):
		print("Alvo não pode receber dano: ", target.name)
		return

	print("\n" + attacker.name + " atacou " + target.name + " causando " + str(damage_amount) + " de dano.")
	target.take_damage(damage_amount)
	entity_damaged.emit(target, damage_amount)

	# Feedback visual/sonoro de ataque
	# Exemplo: game_manager.audio_manager.play_sfx(preload("res://assets/sfx/hit_sound.wav"))

func apply_damage(target: Node, damage_amount: float) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage_amount)
		entity_damaged.emit(target, damage_amount)
		print(target.name + " recebeu " + str(damage_amount) + " de dano.")
	else:
		print("Alvo " + target.name + " não possui método take_damage.")

func check_death(entity: Node) -> void:
	if entity.has_method("get_health") and entity.get_health() <= 0:
		print(entity.name + " morreu.")
		entity_died.emit(entity)
		# Lógica de morte (remover do cenário, etc.)
		if entity is CharacterBody2D:
			entity.queue_free() # Exemplo: remove o inimigo
			game_manager.modify_fear(-10) # Reduz medo ao derrotar inimigo
			game_manager.modify_sanity(5) # Pequeno boost de sanidade

func _on_entity_damaged(entity: Node, damage: float) -> void:
	check_death(entity)

func _on_entity_died(entity: Node) -> void:
	# Lógica adicional quando uma entidade morre
	pass


