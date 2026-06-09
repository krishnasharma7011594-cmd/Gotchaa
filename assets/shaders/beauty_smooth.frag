#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uResolution;
uniform float uSmoothness;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec4 baseColor = texture(uTexture, uv);

    if (uSmoothness <= 0.0) {
        fragColor = baseColor;
        return;
    }

    // Bilateral Filter for Skin Smoothing
    // Preserves edges (eyes, hair) while smoothing skin regions.
    float sigmaS = 4.0; 
    float sigmaR = 0.15 + (1.0 - uSmoothness) * 0.1; 
    
    vec4 sumColor = vec4(0.0);
    float sumWeights = 0.0;
    
    // 5x5 Bilateral Kernel
    for(int i = -2; i <= 2; i++) {
        for(int j = -2; j <= 2; j++) {
            vec2 offset = vec2(float(i), float(j)) / uResolution;
            vec4 sampleColor = texture(uTexture, uv + offset);
            
            float distS = dot(vec2(i, j), vec2(i, j));
            float weightS = exp(-distS / (2.0 * sigmaS * sigmaS));
            
            float distR = distance(baseColor.rgb, sampleColor.rgb);
            float weightR = exp(-(distR * distR) / (2.0 * sigmaR * sigmaR));
            
            float weight = weightS * weightR;
            sumColor += sampleColor * weight;
            sumWeights += weight;
        }
    }
    
    vec4 filtered = sumColor / sumWeights;
    
    // Texture stabilization: keep original sharp detail mixed in
    fragColor = mix(baseColor, filtered, uSmoothness * 0.8);
}
