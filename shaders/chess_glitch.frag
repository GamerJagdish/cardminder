// source https://www.shadertoy.com/view/XddXDM
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uLineColor;
uniform vec4 uBgColor;

out vec4 fragColor;

void main()
{
    vec2 R = FlutterFragCoord().xy;
    R = ceil((R.xy / uResolution.xy - 0.5) * 99.0) / 99.0 + cos(uTime) * 0.2;
    R.x *= 1.0 + pow(sin(uTime + R.y * 2.0), 4.0);
    R *= sin(R * 30.0);
    float val = ceil(R.x * R.y) * 0.2;
    
    fragColor = vec4(vec3(val), 1.0);
}
