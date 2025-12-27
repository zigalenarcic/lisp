#version 330

out vec4 fragColor;

uniform mat4 view_matrix;

uniform vec2 screenSize;
uniform float fovy;
uniform vec2 sun_position;

#define PI 3.14159265f

#define RGB(r, g, b) vec3(r * 0.00392156862, g * 0.00392156862, b * 0.00392156862)

void main()
{
  float aspect = screenSize.x / screenSize.y;

  vec2 coord = 2.0 * (gl_FragCoord.xy / screenSize - 0.5); //  -1 .. 1
  coord.x *= aspect; // make it square

  // coord works.

  // make a direction vector for the pixel
  //         d
  //  +---------------+
  //  |      fov/2--
  // 1|        ---
  //  |   ----
  //  +---
  // tan(fovy/2) = 1 / d
  // screen distance: d = 1/tan(fovy(rad) / 2.0)
  vec3 dir_rel = normalize(vec3(coord.xy, -1/tan(0.5 * radians(fovy))));
  vec4 dir = transpose(view_matrix) * vec4(dir_rel, 1.0);

  // convert to angle pair (yaw, theta)
  vec2 angle = vec2(PI + atan(dir.x, dir.z), atan(dir.y, length(dir.xz)));
  angle.x = mod(PI + angle.x, 2 * PI) - PI;

  vec2 loc = angle;

  vec2 sun_pos = sun_position; // vec2(0.2, 0.1);
  vec2 sun_offset = abs(loc - sun_pos);
  sun_offset.x = mod(PI + sun_offset.x, 2 * PI) - PI;

  float sun_off = length(sun_offset);
  float sun_radius = 0.07;

  vec3 col = vec3(1.0, 0.0, 0.0);

  vec3 sun_color = RGB(0xfd, 0xfe, 0x8f);
  vec3 sky1 = RGB(0xfe, 0xa4, 0x34);
  vec3 sky2 = RGB(0x9b, 0x8d, 0xa4);

  float y_grad = pow(clamp(1 - 2.6 * loc.y, 0.0, 1.0), 4.0);
  float x_modifier = 0.2 + pow((PI - abs(loc.x - sun_pos.x)) / PI, 2.0);
  float sky_col_x = clamp(0, 1, x_modifier * y_grad);
  col = mix(sky2, sky1, sky_col_x)* smoothstep(-0.001, 0.0, loc.y);

  // draw sun/moon
  col = mix(sun_color, col, smoothstep(0.0, 0.003, sun_off - sun_radius));

  // Draw lines
#if 0
  col += 0.8 * mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), smoothstep(0.0, 0.002, abs(loc.y)));
  col += 0.4 * mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), smoothstep(0.0, 0.002, abs(loc.y + 0.1)));
  col += 0.8 * mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), smoothstep(0.0, 0.002, abs(loc.y)));
  col += 0.8 * mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), smoothstep(0.0, 0.002, abs(loc.y - 0.1)));
  col += 0.8 * mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), smoothstep(0.0, 0.002, abs(loc.y - 0.2)));

  col += 0.8 * mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), smoothstep(0.0, 0.002, abs(loc.x - 0.00)));
  col += 0.8 * mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), smoothstep(0.0, 0.002, abs(loc.x - 0.2)));
#endif

  fragColor = vec4(col, 1.0);
}
