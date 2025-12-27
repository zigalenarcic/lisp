#version 330

out vec4 fragColor;

uniform ivec2 screen;

void main()
{
  const float m2[4] = float[4](0.0, 2.0, 3.0, 1.0);
  const float m3[16] = float[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

  vec2 rel_pos = 2.0 * vec2(gl_FragCoord.x / screen.x, gl_FragCoord.y / screen.y) - 1.0;
  rel_pos.x = rel_pos.x * screen.x / screen.y;

  vec3 col = vec3(1.0 - step(0.4, length(rel_pos)), 0.0, clamp(0.7 * rel_pos.y + 0.3, 0.0, 1.0));

  //col = mix(vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), length(col));

  //float gray = 0.7 * (col.x + col.y + col.z);
  //col = vec3(gray, gray, gray);

#if 0
#if 0
  float x_off = mod(gl_FragCoord.x, 2.0);
  float y_off = mod(gl_FragCoord.y, 2.0);

  col += 0.4 * 0.25 * (m2[int(y_off * 2.0 + x_off)] - 2);
  col = vec3(step(0.4, col.x), step(0.4, col.g), step(0.4, col.b));
#else
  float x_off = mod(gl_FragCoord.x, 4.0);
  float y_off = mod(gl_FragCoord.y, 4.0);

  col += 0.4 * (1/16.0) * (m3[int(y_off * 4.0 + x_off)] - 8.0);
  col = vec3(step(0.4, col.x), step(0.4, col.g), step(0.4, col.b));
#endif
#endif

  fragColor = vec4(col, 1.0);
}
