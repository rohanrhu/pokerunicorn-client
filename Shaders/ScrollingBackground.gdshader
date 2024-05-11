shader_type canvas_item;

uniform float horizontal_speed = 0;
uniform float vertical_speed = 0;

uniform sampler2D overlay_texture;

void fragment () {
	COLOR = texture(TEXTURE, vec2(UV.x + TIME * horizontal_speed, UV.y + TIME * vertical_speed));
	COLOR.a *= texture(overlay_texture, vec2(UV.y, 0)).a;
}