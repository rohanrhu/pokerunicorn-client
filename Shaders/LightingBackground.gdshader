/*
 * PokerUnicorn Game Client
 * Copyright (C) 2023, Pokersite
 * https://rohanrhu.github.io/pokerunicorn-website/
 */

shader_type canvas_item;

uniform bool indicate = false;
uniform vec2 size;
uniform vec2 lighting_point = vec2(0.5);
uniform float indicating_power: hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float radius_base: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float static_power: hint_range(0.0, 1.0, 0.1) = 0.5;

void fragment() {
	if (indicate) {
		float ratio = 1.0;

		if (size.x > size.y) {
			ratio = size.x / size.y;
		} else if (size.x < size.y) {
			ratio = size.y / size.x;
		}

		float dx = UV.x - lighting_point.x;
		float dy = UV.y - lighting_point.y;
		dx *= ratio;

		float r = radius_base + sqrt(pow(dx, 2.0) + pow(dy, 2.0));
		r *= indicating_power;

		COLOR.a = r;
	}
	
	float ratio = 1.0;
	vec2 csize = vec2(0.5);
	vec2 clp = vec2(0.1);
	
	if (csize.x > csize.y) {
		ratio = csize.x / csize.y;
	} else if (csize.x < csize.y) {
		ratio = csize.y / csize.x;
	}
	
	float dx = UV.x - clp.x;
	float dy = UV.y - clp.y;
	dx *= ratio;
	
	float r = sqrt(pow(dx, 2.0) + pow(dy, 2.0));
	r *= 1.0 - static_power;
	
	COLOR.a -= 1.0 - r;
}
