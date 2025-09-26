shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// This receives the bass value from our GDScript
uniform float bass_level; 
// This lets us control the MAX saturation boost from the Inspector
uniform float saturation_boost : hint_range(0.0, 2.0) = 0.5;

// Helper function to convert RGB color to HSV
// (Hue, Saturation, Value)
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Helper function to convert HSV color back to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    // Get the color of the pixel from the SubViewport's texture
    vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    
    // Convert the screen color to HSV
    vec3 hsv = rgb2hsv(screen_color);
    
    // THE MAGIC: Increase the saturation (the 'y' component of hsv)
    // The amount is based on the bass_level and our max boost value.
    hsv.y += bass_level * saturation_boost;
    
    // Make sure saturation doesn't go over 1.0
    hsv.y = clamp(hsv.y, 0.0, 1.0);
    
    // Convert the modified HSV color back to RGB
    vec3 final_color = hsv2rgb(hsv);
    
    // Apply the final color to the screen
    COLOR.rgb = final_color;
}