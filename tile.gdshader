shader_type spatial;
render_mode unshaded, depth_prepass_alpha;

uniform sampler2DArray tex_array : filter_nearest, source_color;

uniform vec3 fog_color : source_color = vec3(0.7, 0.8, 1.0);
uniform float fog_start = 1.0;
uniform float fog_end = 20.0;

varying float y_index;
varying float texId;

void vertex() {
	texId = INSTANCE_CUSTOM.x;
	y_index = INSTANCE_CUSTOM.y;
}

void fragment() {
    vec4 color = texture(tex_array, vec3(UV, texId));

	float fog_raw = CAMERA_POSITION_WORLD.y - y_index - fog_start;
	float fog_factor = smoothstep(0, fog_end-fog_start, fog_raw);

	vec3 final_color = mix(color.rgb, fog_color, fog_factor);
    ALBEDO = final_color.rgb;
	ALPHA = color.a;
}