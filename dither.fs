#version 330

in vec2 fragTexCoord;
out vec4 finalColor;

uniform sampler2D texture0;
uniform vec2 resolution;

float luma(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

float bayer(int iter, vec2 rc) {
    float sum = 0.0;
    for(int i = 0; i < 1; ++i) {
        if (i >= iter) break;
        vec2 bsize = vec2(pow(2.0, float(i+1)));
        vec2 t = mod(rc, bsize) / bsize;
        int idx = int(dot(floor(t*2.0), vec2(2.0,1.0)));
        float b = 0.0;
        if (idx == 0) { b = 0.0; } 
        else if (idx == 1) { b = 2.0; } 
        else if (idx == 2) { b = 3.0; } 
        else { b = 1.0; }
        sum += b * pow(4.0, float(iter-i-1));
    }
    float phi = pow(4.0, float(iter)) + 1.0;
    return (sum + 1.0) / phi;
}

void main() {
    float dither_amount = 0.4; // Reduced dither intensity

    float thresh = bayer(1, fragTexCoord * (resolution * dither_amount));
    
    vec3 cam_color = texture(texture0, fragTexCoord).rgb;
    float luma_val = luma(cam_color);
    
    // More lenient threshold - allow more colors to pass through
    float threshold_factor = 0.3; // Lower threshold
    float dither_strength = smoothstep(thresh - threshold_factor, thresh + threshold_factor, luma_val);
    
    // Apply dithering more gently
    cam_color = cam_color * mix(0.0, 1.0, dither_strength);
    
    vec2 pixelSize = 1.0 / resolution;
    vec4 averageColor = vec4(0.0);
    
    for (int dx = -5; dx <= 5; dx++) {
        for (int dy = -5; dy <= 5; dy++) {
            vec2 offset = vec2(dx, dy) * pixelSize;
            averageColor += texture(texture0, fragTexCoord + offset);
        }
    }
    
    averageColor /= 121.0; // 11x11 grid = 121 samples
    
    float amount = 0.1; // Constant glow (no time variation)
    
    // Apply glow to dithered color
    vec3 finalColor3 = cam_color * (1.0 + amount * 5.0);
    
    finalColor = vec4(finalColor3, 1.0);
}