shader_type canvas_item;

const int max_vu = 512;
const float segment_count = 40.0;

uniform float inactive_mask = 0.2;
uniform bool outline_only;
uniform vec3 color_top;
uniform vec3 color_bottom;
uniform float alpha;
uniform int columns_count;
uniform float[max_vu] freq_data;

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	float vu_count = float(columns_count);
	vec2 pos = vec2(floor(uv.x * vu_count) / vu_count, floor(uv.y * segment_count) / segment_count);
	float fft = freq_data[int(uv.x * vu_count)];
	//vec3 color = mix(color_bottom, color_top, sqrt(uv.y));
	vec4 color = vec4(mix(color_bottom, color_top, sqrt(uv.y)), alpha);
	float mask = pos.y < fft ? 1.0 : inactive_mask;
	vec2 dist = fract((uv - pos) * vec2(vu_count, segment_count)) - 0.5;
	float led = smoothstep(0.5, 0.35, abs(dist.x)) * smoothstep(0.5, 0.35, abs(dist.y));
	float bigger_led = smoothstep(1, 0.35, abs(dist.x)) * smoothstep(1, 0.35, abs(dist.y));
	float outline = bigger_led - led;
	
	led = outline_only ? outline : led;
	
	//COLOR = vec4(led * color * mask, alpha);
	COLOR = vec4(led * color * mask);
}
