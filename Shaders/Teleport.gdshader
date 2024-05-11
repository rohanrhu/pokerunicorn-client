shader_type canvas_item;
render_mode unshaded;

uniform float progress: hint_range(0.0, 1.0);
uniform float noise_desnity = 60;
uniform float beam_size: hint_range(0.01, 0.15);
uniform vec4 color: source_color = vec4(0.0, 1.02, 1.2, 1.0);

uniform bool is_screen_reading = false;

uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

vec2 random(vec2 uv){
	uv = vec2(dot(uv, vec2(127.1,311.7)),
			  dot(uv, vec2(269.5,183.3)));
	return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
	vec2 uv_index = floor(uv);
	vec2 uv_fract = fract(uv);

	vec2 blur = smoothstep(0.0, 1.0, uv_fract);

	return mix(mix(dot(random(uv_index + vec2(0.0,0.0) ), uv_fract - vec2(0.0,0.0)),
				   dot(random(uv_index + vec2(1.0,0.0)), uv_fract - vec2(1.0,0.0)), blur.x),
			   mix(dot(random(uv_index + vec2(0.0,1.0)), uv_fract - vec2(0.0,1.0)),
				   dot(random(uv_index + vec2(1.0,1.0)), uv_fract - vec2(1.0,1.0)), blur.x), blur.y) * 0.5 + 0.5;
}

void fragment() {
	float noise = noise(UV * noise_desnity) * UV.y;
	
	float d1 = step(progress, noise);
	float d2 = step(progress - beam_size, noise);
	
	vec3 beam = vec3(d2 - d1) * color.rgb;
	
	vec4 tex = texture(screen_texture, SCREEN_UV).rgba;
	
	if (is_screen_reading) {
		tex.rgb += beam;
		tex.a *= d2;
		
		COLOR.rgba = tex.rgba;
	} else {
		COLOR.rgb += beam;
		COLOR.a *= d2;
	}
}