// source https://www.shadertoy.com/view/mdc3zr
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uLineColor;
uniform vec4 uBgColor;

out vec4 fragColor;

float sussy(float x, float y) {
    float a = max(abs(abs(x) - 4.0), abs(y + sign(x) * 0.5));
    float b = max(abs(abs(x * 2.0) - 5.0) - 2.0, abs(abs(y * 2.0) - 2.0));
    float c = max(abs(abs(abs(x * 2.0) - 5.0) - 2.0), abs(y * 2.0 + sign(x) * 4.0));
    
    return min(min(a, b), c) - 1.0;
}

float impostor(float x, float y) {
    float a = mod(x + 2.0 * floor(y * 0.2 - floor((x * 5.0 + y * 2.0) / 66.0 + 0.5) * 0.6 + 0.5) - 6.0, 12.0) - 6.0;
    float b = mod(y - 3.0 * floor((x * 5.0 + y * 2.0) / 66.0 + 0.5) - 2.5, 5.0) - 2.5;
    
    return -sussy(a, b);
}

vec3 among(vec2 z) {
    z = vec2(6.0 * log(max(dot(z, z), 0.0001)), 10.5 * atan(z.y, z.x)) - vec2(8.0, 2.0) * uTime;
    
    float blur = 0.0; 
        
    for(float i = 0.0; i < 0.7; i += 0.07) {
        blur += step(0.0, impostor(z.x - i, z.y - 0.25 * i));
        blur += step(0.0, impostor(z.x - i, z.y - 0.25 * i - 11.0)) * 0.4;
    }
    
    return vec3(blur * 0.1, 0.0, 0.2);
}

void main() {
    vec2 us = (2.0 * FlutterFragCoord().xy - uResolution.xy) / uResolution.y * 15.0;

    fragColor = vec4(among(us), 1.0);
}