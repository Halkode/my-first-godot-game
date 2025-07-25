class_name LightingSystem
extends Node2D

# Sistema de iluminação dinâmica inspirado no Darkwood
signal visibility_changed(visible_area: Array)

@export var base_visibility_radius: float = 100.0
@export var max_visibility_radius: float = 200.0
@export var light_decay_rate: float = 0.8
@export var fear_affects_vision: bool = true
@export var global_light_intensity: float = 1.0 # Nova propriedade para luz global

var player_node: Node2D
var game_manager: GameManager
var visibility_mask: Image
var visibility_texture: ImageTexture

# Luzes no cenário
var scene_lights: Array[Dictionary] = []
var torch_lights: Array[Node2D] = []

# Shader para escuridão
var darkness_shader: Shader
var darkness_material: ShaderMaterial

func _ready() -> void:
	# Encontrar referências
	player_node = get_tree().get_first_node_in_group("player")
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	# Configurar máscara de visibilidade
	setup_visibility_mask()
	
	# Configurar shader de escuridão
	setup_darkness_shader()
	
	# Conectar sinais do GameManager
	if game_manager:
		game_manager.fear_changed.connect(_on_fear_changed)
		game_manager.sanity_changed.connect(_on_sanity_changed)

func setup_visibility_mask() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	visibility_mask = Image.create(int(viewport_size.x), int(viewport_size.y), false, Image.FORMAT_RGBA8)
	visibility_texture = ImageTexture.new()

func setup_darkness_shader() -> void:
	# Criar material com shader para escuridão
	darkness_material = ShaderMaterial.new()
	
	# Shader simples para escuridão (você pode expandir isso)
	var shader_code = """
shader_type canvas_item;

uniform float darkness_intensity : hint_range(0.0, 1.0) = 0.8;
uniform vec2 light_position;
uniform float light_radius = 100.0;
uniform sampler2D visibility_mask;
uniform float global_light_multiplier = 1.0; // Novo uniforme para luz global

void fragment() {
	vec2 screen_pos = SCREEN_UV;
	vec4 mask_color = texture(visibility_mask, screen_pos);
	
	float distance_to_light = distance(screen_pos * get_viewport().get_visible_rect().size, light_position);
	float light_intensity = 1.0 - smoothstep(0.0, light_radius, distance_to_light);
	
	float final_darkness = darkness_intensity * (1.0 - light_intensity) * (1.0 - mask_color.r);
	
	// Aplicar o multiplicador de luz global
	final_darkness = clamp(final_darkness - (1.0 - global_light_multiplier), 0.0, 1.0);
	
	COLOR = vec4(0.0, 0.0, 0.0, final_darkness);
}
"""
	
	darkness_shader = Shader.new()
	darkness_shader.code = shader_code
	darkness_material.shader = darkness_shader

func _process(delta: float) -> void:
	if player_node:
		update_visibility_around_player()
		update_darkness_overlay()

func update_visibility_around_player() -> void:
	if not player_node:
		return
	
	var current_radius = calculate_current_visibility_radius()
	var player_pos = player_node.global_position
	
	# Limpar máscara de visibilidade
	visibility_mask.fill(Color.BLACK)
	
	# Adicionar visibilidade ao redor do jogador
	add_circular_light(player_pos, current_radius, 1.0)
	
	# Adicionar luzes do cenário
	for light_data in scene_lights:
		if light_data.get("active", true):
			add_circular_light(light_data.position, light_data.radius, light_data.intensity)
	
	# Atualizar textura
	visibility_texture.set_image(visibility_mask)

func calculate_current_visibility_radius() -> float:
	var base_radius = base_visibility_radius
	
	if game_manager and fear_affects_vision:
		var fear_factor = game_manager.get_fear_percentage()
		var sanity_factor = game_manager.get_sanity_percentage()
		
		# Medo reduz visibilidade, sanidade baixa também
		var vision_modifier = (1.0 - fear_factor * 0.5) * (0.5 + sanity_factor * 0.5)
		base_radius *= vision_modifier
	
	return clamp(base_radius, 50.0, max_visibility_radius)

func add_circular_light(center: Vector2, radius: float, intensity: float) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var image_center = Vector2(center.x, center.y)
	
	# Converter coordenadas do mundo para coordenadas da imagem
	var camera = get_viewport().get_camera_2d()
	if camera:
		image_center = center - camera.global_position + viewport_size / 2
	
	# Desenhar círculo de luz na máscara
	for x in range(max(0, int(image_center.x - radius)), min(int(viewport_size.x), int(image_center.x + radius))):
		for y in range(max(0, int(image_center.y - radius)), min(int(viewport_size.y), int(image_center.y + radius))):
			var distance = Vector2(x, y).distance_to(image_center)
			if distance <= radius:
				var light_value = intensity * (1.0 - (distance / radius)) * light_decay_rate
				var current_color = visibility_mask.get_pixel(x, y)
				var new_value = min(1.0, current_color.r + light_value)
				visibility_mask.set_pixel(x, y, Color(new_value, new_value, new_value, 1.0))

func update_darkness_overlay() -> void:
	if darkness_material and player_node:
		darkness_material.set_shader_parameter("light_position", player_node.global_position)
		darkness_material.set_shader_parameter("light_radius", calculate_current_visibility_radius())
		darkness_material.set_shader_parameter("visibility_mask", visibility_texture)
		darkness_material.set_shader_parameter("global_light_multiplier", global_light_intensity) # Passa o multiplicador de luz global
		
		# Ajustar intensidade da escuridão baseada no medo
		var darkness_intensity = 0.8
		if game_manager:
			var fear_factor = game_manager.get_fear_percentage()
			darkness_intensity = 0.6 + (fear_factor * 0.3)
		
		darkness_material.set_shader_parameter("darkness_intensity", darkness_intensity)

func add_scene_light(position: Vector2, radius: float, intensity: float = 1.0, active: bool = true) -> void:
	var light_data = {
		"position": position,
		"radius": radius,
		"intensity": intensity,
		"active": active
	}
	scene_lights.append(light_data)

func toggle_scene_light(index: int) -> void:
	if index >= 0 and index < scene_lights.size():
		scene_lights[index]["active"] = !scene_lights[index]["active"]

func add_torch_light(torch_node: Node2D, radius: float = 80.0) -> void:
	torch_lights.append(torch_node)
	add_scene_light(torch_node.global_position, radius, 0.8, true)

func remove_torch_light(torch_node: Node2D) -> void:
	var index = torch_lights.find(torch_node)
	if index != -1:
		torch_lights.remove_at(index)
		# Remover da lista de luzes do cenário também
		for i in range(scene_lights.size() - 1, -1, -1):
			if scene_lights[i].position.distance_to(torch_node.global_position) < 10:
				scene_lights.remove_at(i)
				break

func create_flickering_effect(light_index: int, flicker_intensity: float = 0.3) -> void:
	if light_index >= 0 and light_index < scene_lights.size():
		var tween = create_tween()
		tween.set_loops()
		
		var base_intensity = scene_lights[light_index]["intensity"]
		var min_intensity = base_intensity * (1.0 - flicker_intensity)
		var max_intensity = base_intensity * (1.0 + flicker_intensity)
		
		tween.tween_method(
			func(value): scene_lights[light_index]["intensity"] = value,
			min_intensity,
			max_intensity,
			randf_range(0.1, 0.3)
		)
		tween.tween_method(
			func(value): scene_lights[light_index]["intensity"] = value,
			max_intensity,
			min_intensity,
			randf_range(0.1, 0.3)
		)

func _on_fear_changed(new_fear: float) -> void:
	# Medo afeta a visibilidade
	pass

func _on_sanity_changed(new_sanity: float) -> void:
	# Sanidade baixa pode causar alucinações visuais
	if new_sanity < 30:
		create_hallucination_effect()

func create_hallucination_effect() -> void:
	# Criar efeito de alucinação (luzes falsas, sombras)
	var random_pos = player_node.global_position + Vector2(
		randf_range(-200, 200),
		randf_range(-200, 200)
	)
	
	add_scene_light(random_pos, 50.0, 0.5, true)
	
	# Remover após um tempo
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = randf_range(1.0, 3.0)
	timer.one_shot = true
	timer.timeout.connect(func(): 
		scene_lights.pop_back()
		timer.queue_free()
	)
	timer.start()

func get_darkness_material() -> ShaderMaterial:
	return darkness_material

func set_global_light_intensity(intensity: float) -> void:
	global_light_intensity = clamp(intensity, 0.0, 1.0)
	print("Intensidade da luz global ajustada para: ", global_light_intensity)


