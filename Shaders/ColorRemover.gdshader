shader_type canvas_item;

uniform vec4 u_color_key: source_color;
uniform vec4 u_replacement_color: source_color;
uniform float tolerance : hint_range(0.0, 1.0, 0.01);

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    vec4 d4 = abs(col - u_color_key);
    float d = max(max(d4.r, d4.g), d4.b);
    if (d < tolerance) {
        col = u_replacement_color;
    }
    COLOR = col;
}