#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float SCAN_OPACITY = 0.35;

float scanDark(float row) {
  if (row < 2.0) return 0.0;
  if (row < 3.0) return 0.30 * (row - 2.0);
  return 0.30;
}

float vignette(vec2 uv) {
  float d = length(uv - 0.5);
  if (d <= 0.44) return 0.0;
  if (d <= 0.58) return mix(0.0, 0.05, (d - 0.44) / 0.14);
  if (d <= 0.78) return mix(0.05, 0.32, (d - 0.58) / 0.20);
  return mix(0.32, 0.62, clamp((d - 0.78) / 0.22, 0.0, 1.0));
}

void main() {
  vec4 pixel = texture(tex, v_texcoord);
  float row = mod(gl_FragCoord.y, 4.0);

  vec3 color = pixel.rgb;
  color = mix(color, vec3(0.0), scanDark(row) * SCAN_OPACITY);
  color = mix(color, vec3(0.0), vignette(v_texcoord));

  fragColor = vec4(color, pixel.a);
}
