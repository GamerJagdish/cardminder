// source: https://www.shadertoy.com/view/s3fSzX
#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uLineColor;
uniform vec4 uBgColor;

out vec4 fragColor;

// Full 32-bit float sin to prevent mobile GPU hardware SFU sin() precision loss
// when multiplied by 1e4 across high-frequency fbm octaves.
float hpSin(float x) {
    x = x - floor(x * 0.15915494309 + 0.5) * 6.28318530718;
    x = x > 1.57079632679 ? 3.14159265359 - x : (x < -1.57079632679 ? -3.14159265359 - x : x);
    float x2 = x * x;
    return x * (1.0 - x2 * (0.16666666667 - x2 * (0.00833333333 - x2 * 0.00019841270)));
}

mat2 rot(float a) {
    float s = sin(a); float c = cos(a);
    return mat2(c, -s, s, c);
}

float hash(vec2 p) { 
    return fract(1e4 * hpSin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(hpSin(p.y * 13.0 + p.x)))); 
}

float noise(vec2 x) {
    vec2 i = floor(x); vec2 f = fract(x);
    float a = hash(i); float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0)); float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 x) {
    float v = 0.0; float a = 0.5; vec2 shift = vec2(100.0); mat2 rot2 = rot(0.5);
    for (int i = 0; i < 5; ++i) {
        v += a * noise(x); x = rot2 * x * 2.0 + shift; a *= 0.5;
    }
    return v;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 p = (fragCoord.xy - 0.5 * uResolution.xy) / min(uResolution.x, uResolution.y);
    float t = uTime * 0.08; 
    
    vec2 q = vec2(fbm(p * 2.0 + vec2(0.0, t)), fbm(p * 2.0 + vec2(1.0, t)));
    vec2 r = vec2(fbm(p * 2.0 + 1.0 * q + vec2(1.7, 9.2) + 0.15 * t), fbm(p * 2.0 + 1.0 * q + vec2(8.3, 2.8) + 0.126 * t));
    float f = fbm(p * 1.5 + r);

    vec3 cNegroFondo = vec3(0.035, 0.047, 0.145); 
    vec3 cMoradoOsc  = vec3(0.192, 0.133, 0.474); 
    vec3 cMoradoMed  = vec3(0.305, 0.168, 0.584); 
    vec3 cPurpura    = vec3(0.435, 0.305, 0.620); 
    vec3 cNeonClaro  = vec3(0.721, 0.352, 0.796); 
    vec3 cDestello   = vec3(0.674, 0.447, 0.792); 

    vec3 color = mix(cNegroFondo, cMoradoOsc, smoothstep(0.1, 0.6, f));
    color = mix(color, cMoradoMed, smoothstep(0.4, 0.8, f));
    color = mix(color, cPurpura, smoothstep(0.6, 1.0, f));
    color = mix(color, cNeonClaro, pow(f, 3.0) * 0.8);
    
    float spark = pow(fbm(p * 6.0 - t * 2.0), 4.0);
    color += cDestello * spark * 0.4;

    vec2 uvVignette = fragCoord.xy / uResolution.xy;
    float vignette = uvVignette.x * uvVignette.y * (1.0 - uvVignette.x) * (1.0 - uvVignette.y);
    color *= clamp(pow(16.0 * vignette, 0.25), 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}