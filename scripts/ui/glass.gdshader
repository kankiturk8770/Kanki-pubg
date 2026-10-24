shader_type canvas_item;
// Frosted glass: what is behind the panel is blurred and tinted with the
// panel colour (its alpha = how much tint). Used by ui_theme.gd glass().

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float blur = 2.5;

void fragment() {
	vec2 step_px = SCREEN_PIXEL_SIZE * blur;
	vec3 sum = vec3(0.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			sum += texture(screen_texture, SCREEN_UV + vec2(float(x), float(y)) * step_px).rgb;
		}
	}
	vec3 behind = sum / 25.0;
	COLOR = vec4(mix(behind, COLOR.rgb, COLOR.a), step(0.001, COLOR.a));
}
