shader_type canvas_item;
render_mode unshaded;

uniform sampler2D fog_mask : filter_nearest, repeat_disable;
uniform vec4 unexplored_color : source_color = vec4(0.010, 0.014, 0.020, 1.0);
uniform vec4 explored_color : source_color = vec4(0.025, 0.038, 0.050, 1.0);
uniform vec2 arena_tiles = vec2(10.0, 10.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * value_noise(p);
		p = p * 2.03 + vec2(19.1, 7.7);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec4 mask_sample = texture(fog_mask, UV);
	if (mask_sample.a < 0.01) {
		discard;
	}

	vec2 smoke_uv = UV * arena_tiles * 0.55;
	float drift = TIME * 0.030;
	float n = fbm(smoke_uv + vec2(drift, -drift * 0.7));
	n = mix(n, fbm(smoke_uv * 2.3 - vec2(drift * 1.4, drift)), 0.45);

	vec4 fog_color = mix(explored_color, unexplored_color, mask_sample.r);
	fog_color.rgb += (n - 0.5) * 0.028;
	fog_color.a = mix(0.88, 0.985, n) * mask_sample.a;
	COLOR = fog_color;
}
