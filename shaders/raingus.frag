// source https://www.shadertoy.com/view/md33zr
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uLineColor;
uniform vec4 uBgColor;

out vec4 fragColor;

vec3 sussy(vec3 x, vec3 y) {
    vec3 a = max(abs(abs(x) - 4.0), abs(y + sign(x) * 0.5));
    vec3 b = max(abs(abs(x * 2.0) - 5.0) - 2.0, abs(abs(y * 2.0) - 2.0));
    vec3 c = max(abs(abs(abs(x * 2.0) - 5.0) - 2.0), abs(y * 2.0 + sign(x) * 4.0));
    
    return min(min(a, b), c) - 1.0;
}

vec3 impostor(vec3 x, vec3 y) {
    vec3 round1 = floor((x * 5.0 + y * 2.0) / 66.0 + 0.5);
    vec3 round2 = floor(y * 0.2 - round1 * 0.6 + 0.5);
    vec3 a = mod(x + 2.0 * round2 - 6.0, 12.0) - 6.0;
    vec3 b = mod(y - 3.0 * round1 - 2.5, 5.0) - 2.5;
    
    return -sussy(a, b);
}

vec3 among(vec2 z) {
    vec3 i = vec3(0.0, 1.0, 2.0);
    return sign(impostor(vec3(z.x) - i * 4.0, vec3(z.y) - i)) + 1.1;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 us = (2.0 * fragCoord - uResolution.xy) / uResolution.y * 24.0 + 2.0 * uTime;

    fragColor = vec4(among(us), 1.0);
}
