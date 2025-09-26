shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float lod: hint_range(0.0, 5) = 0.0;
uniform float overlay_alpha: hint_range(0.0, 1.0) = 0.784; // 200/255

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);

	// Apply black overlay
	vec3 black_overlay = vec3(0.0, 0.0, 0.0);
	color.rgb = mix(color.rgb, black_overlay, overlay_alpha);

	COLOR = color;
}