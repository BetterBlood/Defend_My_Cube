shader_type spatial;
render_mode unshaded;

uniform bool use_billboard;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 background_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float health : hint_range(0.0, 1.0) = 0.5;

void vertex() {
	if (use_billboard){
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}

void fragment() {
	ALBEDO = UV.x < health ? color.rgb : background_color.rgb;
	ALPHA = UV.x < health ? color.a : background_color.a;
}