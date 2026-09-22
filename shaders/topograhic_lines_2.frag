// source https://www.shadertoy.com/view/Xt3yDS
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uLineColor;
uniform vec4 uBgColor;

out vec4 fragColor;

// --------------------------------------------------------
// Simplex(ish) Noise
// Shane https://www.shadertoy.com/view/ldscWH
// --------------------------------------------------------

vec3 hash33(vec3 p) { 
    float n = sin(dot(p, vec3(7.0, 157.0, 113.0)));    
    return fract(vec3(2097152.0, 262144.0, 32768.0) * n) * 2.0 - 1.0;
}

float tetraNoise(in vec3 p)
{
    vec3 i = floor(p + dot(p, vec3(0.333333)));  
    p -= i - dot(i, vec3(0.166666));
    vec3 i1 = step(p.yzx, p);
    vec3 i2 = max(i1, 1.0 - i1.zxy); 
    i1 = min(i1, 1.0 - i1.zxy);    
    vec3 p1 = p - i1 + 0.166666;
    vec3 p2 = p - i2 + 0.333333;
    vec3 p3 = p - 0.5;
    vec4 v = max(0.5 - vec4(dot(p, p), dot(p1, p1), dot(p2, p2), dot(p3, p3)), 0.0);
    vec4 d = vec4(dot(p, hash33(i)), dot(p1, hash33(i + i1)), dot(p2, hash33(i + i2)), dot(p3, hash33(i + 1.0)));
    return clamp(dot(d, v * v * v * 8.0) * 1.732 + 0.5, 0.0, 1.0);
}

#define PI 3.14159265359

vec2 smoothRepeatStart(float x, float size) {
    return vec2(
        mod(x - size / 2.0, size),
        mod(x, size)
    );
}

float smoothRepeatEnd(float a, float b, float x, float size) {
    return mix(a, b,
        smoothstep(
            0.0, 1.0,
            sin((x / size) * PI * 2.0 - PI * 0.5) * 0.5 + 0.5
        )
    );
}

void main()
{
    vec2 fragCoord = FlutterFragCoord().xy;

    // Square uv centered and scaled to the screen height
    vec2 uv = (-uResolution.xy + 2.0 * fragCoord.xy) / uResolution.y;
    
    // Zoom to comfortable mobile scale
    uv /= 1.8;

    float repeatSize = 4.0;
    float x = uv.x - mod(uTime * 0.3, repeatSize / 2.0);
    float y = uv.y;

    vec2 ab; // two sample points on one axis

    float noise;
    float noiseA, noiseB;
    
    // Blend noise at different frequencies, moving in different directions
    ab = smoothRepeatStart(x, repeatSize);
    noiseA = tetraNoise(16.0 + vec3(vec2(ab.x, uv.y) * 1.2, 0.0)) * 0.5;
    noiseB = tetraNoise(16.0 + vec3(vec2(ab.y, uv.y) * 1.2, 0.0)) * 0.5;
    noise = smoothRepeatEnd(noiseA, noiseB, x, repeatSize);

    ab = smoothRepeatStart(y, repeatSize / 2.0);
    noiseA = tetraNoise(vec3(vec2(uv.x, ab.x) * 0.5, 0.0)) * 2.0;
    noiseB = tetraNoise(vec3(vec2(uv.x, ab.y) * 0.5, 0.0)) * 2.0;
    noise *= smoothRepeatEnd(noiseA, noiseB, y, repeatSize / 2.0);

    ab = smoothRepeatStart(x, repeatSize);
    noiseA = tetraNoise(9.0 + vec3(vec2(ab.x, uv.y) * 0.05, 0.0)) * 5.0;
    noiseB = tetraNoise(9.0 + vec3(vec2(ab.y, uv.y) * 0.05, 0.0)) * 5.0;
    noise *= smoothRepeatEnd(noiseA, noiseB, x, repeatSize);

    noise *= 0.75;

    // Blend with a linear gradient, giving isolines organic contour orientation
    noise = mix(noise, dot(uv, vec2(-0.66, 1.0) * 0.4), 0.6);
    
    // Generate crisp, resolution-independent anti-aliased topographic isolines
    float spacing = 0.035;
    float stepVal = fract(noise / spacing);
    float dist = abs(stepVal - 0.5) * 2.0;
    float line = smoothstep(0.72, 0.94, dist);
    
    fragColor = mix(uBgColor, uLineColor, clamp(line, 0.0, 1.0));
}
