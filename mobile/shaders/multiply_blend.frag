#version 460 core

#include <flutter/runtime_effect.glsl>

// --- Uniforms ---
uniform vec2  uResolution;     // Viewport dimensions
uniform float uOpacity;        // Tattoo opacity (0.0 → 1.0)
uniform mat3  uUvTransform;    // Gesture-driven UV transform (translate, scale, rotate)
uniform vec2  uTattooSize;     // Tattoo texture dimensions (for aspect ratio)
uniform float uEdgeSoftness;   // Anti-aliasing edge softness (0.5 → 2.0 px)

// --- Samplers ---
uniform sampler2D uCameraFeed;  // Live camera frame
uniform sampler2D uTattooTex;   // Tattoo PNG (premultiplied alpha)

// --- Output ---
out vec4 fragColor;

// ─────────────────────────────────────────────
// Multiply blend: preserves skin texture under ink
// result = camera * mix(white, tattoo, tattoo.a * opacity)
// ─────────────────────────────────────────────
vec4 multiplyBlend(vec4 base, vec4 overlay, float alpha) {
    vec3 blended = base.rgb * mix(vec3(1.0), overlay.rgb, alpha);
    return vec4(blended, base.a);
}

// ─────────────────────────────────────────────
// Soft edge mask to prevent hard cutoff at texture bounds
// ─────────────────────────────────────────────
float edgeMask(vec2 uv, float softness) {
    vec2 edge = smoothstep(vec2(0.0), vec2(softness), uv) *
                smoothstep(vec2(0.0), vec2(softness), vec2(1.0) - uv);
    return edge.x * edge.y;
}

void main() {
    // Normalized fragment coordinates
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 screenUv  = fragCoord / uResolution;

    // Sample camera feed at screen position
    vec4 cameraColor = texture(uCameraFeed, screenUv);

    // Apply gesture transform (pan, scale, rotate) to get tattoo UV
    vec3 transformedUv = uUvTransform * vec3(screenUv, 1.0);
    vec2 tattooUv      = transformedUv.xy;

    // Aspect-correct the tattoo UV
    float tattooAspect = uTattooSize.x / uTattooSize.y;
    float screenAspect = uResolution.x / uResolution.y;
    tattooUv.x *= screenAspect / tattooAspect;

    // Bounds check — only render within tattoo texture region
    if (tattooUv.x < 0.0 || tattooUv.x > 1.0 ||
        tattooUv.y < 0.0 || tattooUv.y > 1.0) {
        fragColor = cameraColor;
        return;
    }

    // Texel size for MSAA sampling
    vec2 texelSize = vec2(1.0) / uTattooSize;

    // 4x Rotated Grid Supersampling (MSAA) inlined for SkSL and Impeller compatibility
    vec4 s1 = texture(uTattooTex, tattooUv + vec2(-0.125, -0.375) * texelSize);
    vec4 s2 = texture(uTattooTex, tattooUv + vec2( 0.375, -0.125) * texelSize);
    vec4 s3 = texture(uTattooTex, tattooUv + vec2(-0.375,  0.125) * texelSize);
    vec4 s4 = texture(uTattooTex, tattooUv + vec2( 0.125,  0.375) * texelSize);
    vec4 tattooColor = (s1 + s2 + s3 + s4) * 0.25;

    // Edge softness mask (prevents hard borders)
    float mask = edgeMask(tattooUv, uEdgeSoftness / min(uTattooSize.x, uTattooSize.y));

    // Effective alpha: tattoo alpha × user opacity × edge mask
    float effectiveAlpha = tattooColor.a * uOpacity * mask;

    // Multiply blend — ink darkens skin, preserving texture and luminance
    fragColor = multiplyBlend(cameraColor, tattooColor, effectiveAlpha);
}
