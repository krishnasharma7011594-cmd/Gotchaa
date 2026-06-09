#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uResolution;
uniform float uTone; // -1 to 1
uniform float uLighting;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;
    vec4 color = texture(uTexture, uv);

    // Warmth/Coolness (LAB-inspired color shifting)
    color.r += uTone * 0.04;
    color.g += uTone * 0.02;
    color.b -= uTone * 0.04;

    // Lighting simulation (soft highlight boost)
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    float highlight = pow(gray, 2.0);
    color.rgb += highlight * uLighting * 0.2;
    
    // Slight global exposure
    color.rgb *= (1.0 + uLighting * 0.05);

    fragColor = color;
}
