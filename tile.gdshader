shader_type spatial;
render_mode unshaded;

uniform sampler2DArray tex_array : filter_nearest, source_color;
uniform sampler2DArray add_tex_array : filter_nearest, source_color;

uniform vec3 fog_color : source_color = vec3(0.7, 0.8, 1.0);
uniform float fog_start = 1.0;
uniform float fog_end = 9.0;

varying float y_index;
varying float texId;
varying float add_texId;


void vertex() {
	texId = INSTANCE_CUSTOM.x;
	y_index = INSTANCE_CUSTOM.y;
	add_texId = INSTANCE_CUSTOM.z;
}

void fragment() {
    vec4 color = texture(tex_array, vec3(UV, texId));
	vec4 add_color = texture(add_tex_array, vec3(UV, add_texId));

	float fog_raw = CAMERA_POSITION_WORLD.y - y_index - fog_start;
	float fog_factor = smoothstep(0, fog_end-fog_start, fog_raw);

	vec3 final_color = mix(color.rgb, add_color.rgb, add_color.a);
	final_color = mix(final_color.rgb, fog_color, fog_factor);
    ALBEDO = final_color.rgb;
	ALPHA = color.a;
}