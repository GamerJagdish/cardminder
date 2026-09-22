// source: https://www.shadertoy.com/view/llsSzH
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uLineColor;
uniform vec4 uBgColor;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    float aspect = uResolution.x / uResolution.y;
    vec2 uv = fragCoord.xy / uResolution.xy;
    vec2 position = 0.5 - uv;

    vec2 uva = vec2(position.x, position.y / aspect);

    float r = 10.0 * sqrt(dot(uva, uva));
    vec2 uvd = uva;
    uvd.x += 0.1 * cos(10.0 * uvd.y + 0.5 * uTime);
    uvd.y += 0.1 * sin(10.0 * uvd.x + 0.5 * uTime);

    float r1 = 10.0 * sqrt(dot(uvd, uvd));
    float value = sin(20.0 * r1);

    float col = smoothstep(0.01, 0.5, value);
    fragColor = mix(uBgColor, uLineColor, clamp(col, 0.0, 1.0));
}