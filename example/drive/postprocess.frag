#version 330

out vec4 fragColor;

in vec2 vTexCoord;

uniform ivec2 screen;

uniform sampler2D tex;
uniform sampler2D texDepth;

void main()
{
  //const float m2[4] = float[4](0.0, 2.0, 3.0, 1.0);
  //const float m3[16] = float[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

  //vec2 rel_pos = 2.0 * vec2(gl_FragCoord.x / screen.x, gl_FragCoord.y / screen.y) - 1.0;
  //rel_pos.x = rel_pos.x * screen.x / screen.y;

  //vec3 col = vec3(1.0 - step(0.4, length(rel_pos)), 0.0, clamp(0.7 * rel_pos.y + 0.3, 0.0, 1.0));

  //vec3 col = vec3(0.2); fragColor = vec4(col, 1.0);

  ivec2 s = textureSize(tex, 0) - ivec2(1, 1);
  vec2 off = vec2(1.0) / s;

#if 1
  //fragColor = texture(texDepth, texCoord);
  fragColor = 0.001 * texelFetch(texDepth, ivec2(gl_FragCoord.xy), 0);
  fragColor = texelFetch(tex, ivec2(gl_FragCoord.xy), 0);
  //fragColor = 0.3 * vec4(depth, depth, depth, 1.0);
  //fragColor = vec4(depth.z, depth.z, depth.z, 1.0);
  //fragColor = vec4(depth.w, depth.w, depth.w, 1.0);
  //fragColor = texture(tex, texCoord);
#elif 0
  float factor = 2.0;
  vec2 c = trunc(texCoord * s / factor) * factor / s;
  fragColor = texture(tex, c);
  fragColor += texture(tex, c + vec2(off.x, 0.0));
  fragColor += texture(tex, c + off.xy);
  fragColor += texture(tex, c + vec2(0.0, off.y));
  fragColor *= 0.25;
#elif 0
  float factor = 3.0;
  vec2 c = trunc(texCoord * s / factor) * factor / s;
  fragColor = texture(tex, c);
  fragColor += texture(tex, c + vec2(off.x, 0.0));
  fragColor += texture(tex, c + vec2(2 * off.x, 0.0));
  fragColor += texture(tex, c + vec2(0.0, off.y));
  fragColor += texture(tex, c + vec2(off.x, off.y));
  fragColor += texture(tex, c + vec2(2 * off.x, off.y));
  fragColor += texture(tex, c + vec2(0.0, 2 * off.y));
  fragColor += texture(tex, c + vec2(off.x, 2 * off.y));
  fragColor += texture(tex, c + vec2(2 * off.x, 2 * off.y));
  fragColor /= 9;
#else
  float factor = 4.0;
  vec2 c = trunc(texCoord * s / factor) * factor / s;
  fragColor = texture(tex, c);
  fragColor += texture(tex, c + vec2(off.x, 0.0));
  fragColor += texture(tex, c + vec2(2 * off.x, 0.0));
  fragColor += texture(tex, c + vec2(3 * off.x, 0.0));
  fragColor += texture(tex, c + vec2(0.0, off.y));
  fragColor += texture(tex, c + vec2(off.x, off.y));
  fragColor += texture(tex, c + vec2(2 * off.x, off.y));
  fragColor += texture(tex, c + vec2(3 * off.x, off.y));
  fragColor += texture(tex, c + vec2(0.0, 2 * off.y));
  fragColor += texture(tex, c + vec2(off.x, 2 * off.y));
  fragColor += texture(tex, c + vec2(2 * off.x, 2 * off.y));
  fragColor += texture(tex, c + vec2(3 * off.x, 2 * off.y));
  fragColor += texture(tex, c + vec2(0.0, 3 * off.y));
  fragColor += texture(tex, c + vec2(off.x, 3 * off.y));
  fragColor += texture(tex, c + vec2(2 * off.x, 3 * off.y));
  fragColor += texture(tex, c + vec2(3 * off.x, 3 * off.y));
  fragColor /= 16;
#endif


#if 0
  const float m2[4] = float[4](0.0, 2.0, 3.0, 1.0);
  const float m3[16] = float[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

  vec2 rel_pos = 2.0 * vec2(gl_FragCoord.x / screen.x, gl_FragCoord.y / screen.y) - 1.0;
  rel_pos.x = rel_pos.x * screen.x / screen.y;

  vec3 col = fragColor.xyz;

  //col = mix(vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), length(col));

  //float gray = 0.7 * (col.x + col.y + col.z);
  //col = vec3(gray, gray, gray);

#if 1
  float x_off = mod(gl_FragCoord.x, 2.0);
  float y_off = mod(gl_FragCoord.y, 2.0);

  col += 0.4 * 0.25 * (m2[int(y_off * 2.0 + x_off)] - 2);
  col = vec3(step(0.4, col.x), step(0.4, col.g), step(0.4, col.b));
#elif 1
  float x_off = mod(gl_FragCoord.x, 4.0);
  float y_off = mod(gl_FragCoord.y, 4.0);

  col += 0.4 * (1/16.0) * (m3[int(y_off * 4.0 + x_off)] - 8.0);
  col = vec3(step(0.4, col.x), step(0.4, col.g), step(0.4, col.b));
#else
#endif

  fragColor = vec4(col, 1.0);

#endif

}
