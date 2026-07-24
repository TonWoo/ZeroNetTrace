shader_type canvas_item;
render_mode unshaded;

uniform float scanline_strength : hint_range(0.0, 0.35) = 0.12;
uniform float noise_strength : hint_range(0.0, 0.18) = 0.035;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float scan = sin(UV.y * 900.0 * 3.14159265) * 0.5 + 0.5;
	float grain = rand(floor(UV * vec2(1600.0, 900.0)) + floor(TIME * 12.0));
	float value = scan * scanline_strength + grain * noise_strength;
	COLOR = vec4(vec3(value), scanline_strength * 0.32 + noise_strength * 0.20);
}

