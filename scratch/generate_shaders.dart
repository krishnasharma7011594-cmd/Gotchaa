import 'dart:io';

void main() async {
  final dir = Directory('assets/shaders');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  // 1. Noir
  await File('assets/shaders/noir.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;
void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    gray = clamp((gray - 0.5) * 1.5 + 0.5, 0.0, 1.0);
    gray = pow(gray, 1.2);
    fragColor = vec4(vec3(gray), color.a);
}''');

  // 2. Golden Hour
  await File('assets/shaders/golden_hour.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;
void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    // Warm orange-yellow tint & lifted shadows
    color.r = clamp(color.r * 1.1 + 0.1, 0.0, 1.0);
    color.g = clamp(color.g * 1.05 + 0.05, 0.0, 1.0);
    color.b = clamp(color.b * 0.9, 0.0, 1.0);
    fragColor = vec4(color.rgb, color.a);
}''');

  // 3. Arctic
  await File('assets/shaders/arctic.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;
void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    // Cool cyan-blue tint & boosted highlights
    color.r = clamp(color.r * 0.9, 0.0, 1.0);
    color.g = clamp(color.g * 1.05 + (color.g * color.g * 0.1), 0.0, 1.0);
    color.b = clamp(color.b * 1.15 + 0.05, 0.0, 1.0);
    fragColor = vec4(color.rgb, color.a);
}''');

  // 4. Faded
  await File('assets/shaders/faded.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;
void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    // Fade blacks
    color.rgb = clamp(color.rgb * 0.8 + 0.15, 0.0, 1.0);
    // Slight desaturation
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(color.rgb, vec3(gray), 0.3);
    fragColor = vec4(color.rgb, color.a);
}''');

  // 5. Vivid
  await File('assets/shaders/vivid.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;
void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    // Boost saturation heavily
    color.rgb = mix(vec3(gray), color.rgb, 1.8);
    // Boost contrast slightly
    color.rgb = clamp((color.rgb - 0.5) * 1.1 + 0.5, 0.0, 1.0);
    fragColor = vec4(color.rgb, color.a);
}''');

  // 6. Cinematic Teal & Orange
  await File('assets/shaders/cinematic.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;
void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    // Orange highlights / Teal shadows
    vec3 shadowColor = vec3(0.0, 0.3, 0.4);
    vec3 highlightColor = vec3(1.0, 0.6, 0.2);
    vec3 grade = mix(shadowColor, highlightColor, lum);
    // Blend with original
    color.rgb = mix(color.rgb, color.rgb * grade * 1.5, 0.6);
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    fragColor = vec4(color.rgb, color.a);
}''');

  // 7. Vintage Film
  await File('assets/shaders/vintage.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    
    // Grain
    float noise = (rand(uv * 100.0) - 0.5) * 0.15;
    color.rgb += noise;
    
    // Vignette
    float dist = distance(uv, vec2(0.5));
    color.rgb *= smoothstep(0.8, 0.2, dist);
    
    // Green shift in midtones
    float lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    float mid = 1.0 - abs(lum - 0.5) * 2.0;
    color.g += mid * 0.1;
    
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    fragColor = vec4(color.rgb, color.a);
}''');

  // 8. Moody
  await File('assets/shaders/moody.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;
void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    
    // Desaturate
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(color.rgb, vec3(gray), 0.6);
    
    // Deep shadows (crush)
    color.rgb = pow(color.rgb, vec3(1.3));
    
    // Blue-shift darks
    float dark = 1.0 - gray;
    color.b += dark * 0.15;
    color.r -= dark * 0.05;
    
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    fragColor = vec4(color.rgb, color.a);
}''');

  // 9. Pastel Dream
  await File('assets/shaders/pastel.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;
void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    
    // Low contrast
    color.rgb = clamp((color.rgb - 0.5) * 0.8 + 0.5, 0.0, 1.0);
    
    // Pink-purple haze
    color.r = clamp(color.r + 0.15, 0.0, 1.0);
    color.b = clamp(color.b + 0.1, 0.0, 1.0);
    
    fragColor = vec4(color.rgb, color.a);
}''');

  // 10. Chrome
  await File('assets/shaders/chrome.frag').writeAsString('''
#version 460 core
#include <flutter/core.glsl>
precision highp float;
layout(location = 0) uniform sampler2D imageTexture;
layout(location = 1) uniform vec2 resolution;
out vec4 fragColor;
void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(imageTexture, uv);
    
    // Metallic desaturation
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(color.rgb, vec3(gray), 0.8);
    
    // Blown highlights
    color.rgb = pow(color.rgb, vec3(0.8)); // brighten
    
    // Cool silver tone
    color.b = clamp(color.b * 1.1 + 0.05, 0.0, 1.0);
    color.r = clamp(color.r * 0.95, 0.0, 1.0);
    
    fragColor = vec4(color.rgb, color.a);
}''');

  print('Shaders generated!');
}
