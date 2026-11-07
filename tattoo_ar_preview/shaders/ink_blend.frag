#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uCenter;
uniform vec2 uTattooSize;
uniform float uScale;
uniform float uRotation;
uniform float uOpacity;

uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 local = FlutterFragCoord().xy - uCenter;
  float cosAngle = cos(-uRotation);
  float sinAngle = sin(-uRotation);
  local = vec2(
    local.x * cosAngle - local.y * sinAngle,
    local.x * sinAngle + local.y * cosAngle
  );
  local /= max(uScale, 0.0001);
  vec2 uv = local / max(uTattooSize, vec2(1.0)) + vec2(0.5);
  if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
    fragColor = vec4(0.0);
    return;
  }
  vec4 texel = texture(uTexture, uv);
  float alpha = texel.a * uOpacity;
  fragColor = vec4(texel.rgb * uOpacity, alpha);
}
