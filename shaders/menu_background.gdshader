shader_type canvas_item;
render_mode unshaded;

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
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
	for (int i = 0; i < 5; i++) {
		value += amplitude * value_noise(p);
		p = p * 2.02 + vec2(11.3, 5.7);
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	vec3 base = mix(vec3(0.012, 0.017, 0.024), vec3(0.030, 0.042, 0.055), smoothstep(0.0, 1.0, uv.y));
	base *= 1.0 - smoothstep(0.35, 1.0, uv.y) * 0.30;

	vec2 grid_uv = uv * vec2(34.0, 19.0);
	vec2 grid_dist = abs(fract(grid_uv) - 0.5);
	float grid_line = smoothstep(0.478, 0.5, max(grid_dist.x, grid_dist.y));
	base += vec3(0.035, 0.052, 0.062) * grid_line * (0.35 + 0.65 * uv.y);

	float drift = TIME * 0.022;
	float smoke = fbm(uv * vec2(7.0, 4.5) + vec2(drift, -drift * 0.65));
	smoke = smoothstep(0.35, 0.85, smoke);
	base += vec3(0.045, 0.052, 0.058) * smoke * 0.42;

	float glow = exp(-length((uv - vec2(0.78, 0.22)) * vec2(1.05, 1.6)) * 2.8);
	base += vec3(0.255, 0.145, 0.045) * glow * 0.24;

	float vignette = smoothstep(0.35, 0.95, length((uv - 0.5) * vec2(1.22, 1.0)));
	base *= 1.0 - vignette * 0.72;

	float scan = sin(uv.y * 720.0) * 0.0035;
	base += scan;
	COLOR = vec4(base, 1.0);
}
