shader_type canvas_item;

uniform float THICCNESS = 0.03;
uniform float RADIUS = 0.2;
uniform float SPEED = 4.0;

vec2 remap(vec2 coord, vec2 iResolution) {
	return coord / min(iResolution.x, iResolution.y);
}

float circle(vec2 uv, vec2 pos, float rad) {
	return 1.0 - smoothstep(rad,rad+0.005,length(uv-pos));
}

float ring(vec2 uv, vec2 pos, float innerRad, float outerRad, float aa) {
	return (1.0 - smoothstep(outerRad,outerRad+aa,length(uv-pos))) * smoothstep(innerRad-aa,innerRad,length(uv-pos));
}

void fragment() {
	vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
	float aa = 25.0 / min(iResolution.x, iResolution.y);
	vec2 uv = UV;
	uv -= vec2(.5);

	float geo = 0.0;

	geo += ring(uv,vec2(0.0),RADIUS-THICCNESS,RADIUS, aa);

	float rot = -TIME * SPEED;

	uv *= mat2(vec2(cos(rot), sin(rot)), vec2(-sin(rot), cos(rot)));

	float a = atan(uv.x,uv.y)*PI*0.05 + 0.5;

	a = max(a,circle(uv,vec2(0.0,-RADIUS+THICCNESS/2.0),THICCNESS/2.0));

	COLOR = vec4(a*geo);
}