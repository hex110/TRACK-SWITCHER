shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float blur_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 blur_center = vec2(0.5, 0.5);
uniform int samples : hint_range(1, 32) = 16;

void fragment() {
    vec2 direction = SCREEN_UV - blur_center;
    float distance = length(direction);
    direction = normalize(direction);

    vec4 color = vec4(0.0);
    float total_weight = 0.0;

    for (int i = 0; i < samples; i++) {
        float t = float(i) / float(samples - 1);
        float weight = 1.0 - t;
        vec2 sample_uv = SCREEN_UV - direction * blur_strength * distance * t * 0.1;
        color += texture(SCREEN_TEXTURE, sample_uv) * weight;
        total_weight += weight;
    }

    COLOR = color / total_weight;
}