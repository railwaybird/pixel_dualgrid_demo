shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never;

uniform vec3 shadow_color = vec3(0.679, 0.768, 0.87);

void vertex() {
}

void fragment() {
	ALBEDO = shadow_color.rgb;
}