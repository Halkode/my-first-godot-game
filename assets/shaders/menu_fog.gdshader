shader_type canvas_item;

// Névoa em movimento para o fundo do menu principal. Duas camadas de
// ruído fractal deslizando em velocidades diferentes criam parallax,
// e uma vinheta escurece as bordas para dar o clima opressivo.

uniform vec3 fog_color : source_color = vec3(0.30, 0.32, 0.38);
uniform vec3 base_color : source_color = vec3(0.03, 0.03, 0.05);
uniform float fog_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float scroll_speed : hint_range(0.0, 0.5) = 0.02;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.1;

// Ruído por valor: hash pseudoaleatório interpolado suavemente.
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 offset = fract(p);
	// Suavização cúbica (smoothstep) para evitar bordas duras
	vec2 weight = offset * offset * (3.0 - 2.0 * offset);

	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));

	return mix(mix(a, b, weight.x), mix(c, d, weight.x), weight.y);
}

// Soma de oitavas: cada uma com o dobro da frequência e metade da amplitude.
float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		total += value_noise(p) * amplitude;
		p *= 2.0;
		amplitude *= 0.5;
	}
	return total;
}

void fragment() {
	vec2 uv = UV;

	// Duas camadas em direções opostas dão sensação de profundidade
	float near_layer = fbm(uv * 3.0 + vec2(TIME * scroll_speed, TIME * scroll_speed * 0.3));
	float far_layer = fbm(uv * 6.0 - vec2(TIME * scroll_speed * 0.6, TIME * scroll_speed * 0.2));
	float fog = near_layer * 0.65 + far_layer * 0.35;

	vec3 color = mix(base_color, fog_color, fog * fog_intensity);

	// Vinheta radial a partir do centro
	float distance_from_center = length(uv - vec2(0.5));
	float vignette = smoothstep(0.75, 0.15, distance_from_center * vignette_strength);
	color *= mix(0.35, 1.0, vignette);

	COLOR = vec4(color, 1.0);
}
