// source https://www.shadertoy.com/view/Wc3fWS
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uLineColor;
uniform vec4 uBgColor;

out vec4 fragColor;

float among(vec2 p)
{
    // space between amongi
    float w = 5.0 + floor(sin(uTime) * sin(uTime) * 4.0);
    float h = 8.0 + floor(tan(uTime / 4.0));
    
    float row = floor(p.y / h);
    float col = floor(p.x / w);
    
    p.x -= floor(tan(uTime * 3.0)) * row;         // shift rows
    p.y -= floor(tan(uTime * 0.75) * 2.0) * col * col; // shift cols
    
    // final integer position
    int x = int(mod(p.x, w));
    int y = int(mod(p.y, h));
    
    // determine pixel color
    if (y == 5 && (x == 2 || x == 3)) return 0.1; // eyes
    if (
        (y == 0 && (x >= 0 && x <= 2)) ||
        (y >= 1 && y <= 2 && (x >= 0 && x <= 3)) ||
        (y == 3 && (x == 0 || x == 2))
    ) return 0.1; // shadow
    if (
        (y == 3 && (x == 1 || x == 3)) ||
        (y >= 4 && y <= 5 && (x >= 0 && x <= 3)) ||
        (y == 6 && (x >= 1 && x <= 3))
    ) return mod(floor(abs(row)) + floor(abs(col)), 2.0); // body (checkerboard so some amongi are black)
    
    return 0.0;
}

void main()
{
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution.y;
    uv *= 56.0;
    uv += uTime;

    float l = 0.012 + 0.006 * sin(uTime * 2.0);
    fragColor = vec4(
        among(uv),
        among(uv + l),
        among(uv - l),
        1.0
    );
}