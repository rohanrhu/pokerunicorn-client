/*
 * Pixel-sized Border Radius Shader
 * Copyright (C) 2023 Oğuzhan Eroğlu <meowingcate@gmail.com> (https://oguzhaneroglu.com)
 */

shader_type canvas_item;

uniform float width = 10.0;

uniform float canvas_width;
uniform float canvas_height;

void fragment() {
	float px = canvas_width * UV.x;
	float py = canvas_height * UV.y;
	
	float h;

	if ((px <= width) && (py <= width)) {
		h = sqrt(pow(width - px, 2) + pow(width - py, 2));
		COLOR.a = step(h, width);
	} else if ((px >= canvas_width - width) && (py <= width)) {
		h = sqrt(pow(px - (canvas_width - width), 2) + pow(width - py, 2));
		COLOR.a = step(h, width);
	} else if ((px <= width) && (py >= (canvas_height - width))) {
		h = sqrt(pow(width - px, 2) + pow(py - (canvas_height - width), 2));
		COLOR.a = step(h, width);
	} else if ((px >= canvas_width - width) && (py >= (canvas_height - width))) {
		h = sqrt(pow(px - (canvas_width - width), 2) + pow(py - (canvas_height - width), 2));
		COLOR.a = step(h, width);
	}
}
