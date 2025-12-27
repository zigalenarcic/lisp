#version 330

in vec3 outPosition;
in vec3 outColor;
in vec3 outNormal;
in vec2 outRoadPos;

out vec4 fragColor;

void main()
{
  vec3 col = vec3(0.3, 0.3, 0.4);
  col = vec3(0.0);
  //col = outColor;
  float road_width = 40.0;
  float pos1 = 0.0;
  float pos2 = 0.88 * road_width;
  float pos3 = -0.88 * road_width;
  float line_length = 200.0;
  float pos1_factor = max(abs(mod(outRoadPos.y, line_length) - 100.0) - 50.0, 0.0);
  float pos_factor = pos1_factor > 1.0 ? 0.0 : 1.0;

  vec2 road_pos = vec2(abs(outRoadPos.x - pos1), abs(mod(outRoadPos.y, line_length) - 100.0));

  //float dist = min(min(max(abs(outRoadPos.x - pos1), 0.2 * pos1_factor), abs(outRoadPos.x - pos2)), abs(outRoadPos.x - pos3));
  float lw = 1.4;
  vec2 line_dist = abs(road_pos) - vec2(lw, line_length / 4);
  float dist = 1.0 * length(max(line_dist, 0.0)) + min(max(line_dist.x, line_dist.y), 0.0);

  dist = min(dist, max(abs(outRoadPos.x - pos2) - lw, 0.0) + min(abs(outRoadPos.x - pos2) - lw, 0.0));
  dist = min(dist, max(abs(outRoadPos.x - pos3) - lw, 0.0) + min(abs(outRoadPos.x - pos3) - lw, 0.0));

  //float road_scale = length(vec2(dFdx(outRoadPos.x), dFdy(outRoadPos.x)));
  //float road_scale = fwidth(outRoadPos.x);

  //float w = abs(dFdy(dist));
  //float w = 10* fwidth(dist);
  //float w = 10* fwidth(dist);
  float w = length(vec2(dFdx(dist), dFdy(dist)));
  float line_threshold = 0.0;

  float alpha = 1.0;

  //float road_scale2 = 1 - 12 * road_scale;

  //dist *= road_scale2;

  //alpha *= 1 - 10 * road_scale;

  //col = col + mix(vec3(0.0, 0.0, 0.0), vec3(1.0), 1 - step(0.017, abs(dist)));
  col += alpha * mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), smoothstep(line_threshold - 0.5 * w, line_threshold + 0.5 * w, dist));
  //col += alpha * mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), step(line_threshold, dist));

  //col = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), step(0.0, dist));
  //col = vec3(dist * 0.1);
  // fog
  //col = mix(vec3(0.4, 0.4, 0.4), col, clamp(1 - outPosition.z * 0.001, 0, 1));

  //float intensity = 1.0 - smoothstep(0.2, 0.5, abs(outRoadPos.x));

  float period = 20.0;
  float coordinate_x = outRoadPos.x;
  float scalar_field = abs(mod(outRoadPos.x, period) - 0.5 * period);

  float lwidth = 2.0;
  float laa = 1.8;

  //float deriv = fwidth(coordinate_x);
  float deriv = length(vec2(dFdx(coordinate_x), dFdy(coordinate_x)));
  //float deriv = max(abs(dFdx(coordinate_x)), abs(dFdy(coordinate_x)));

  laa = 1.5 * deriv;

  float draw_width = lwidth;
  draw_width = max(lwidth, deriv);

  float intensity = smoothstep(0.5 * (draw_width + laa), 0.5 * (draw_width - laa), scalar_field);
  //lwidth = 0.5 * max(abs(dFdx(scalar_field)), abs(dFdy(scalar_field)));
  //lwidth = 0.5 * length(vec2(dFdx(scalar_field), dFdy(scalar_field)));
  //float intensity = 1.0 - step(lwidth, scalar_field);

  //intensity = 1.0 - 0.3 * scalar_field;

  intensity = clamp(intensity, 0.0, 1.0);
  intensity *= clamp(lwidth / draw_width, 0.0, 1.0);
  vec3 road_col = vec3(0.0);
  //road_col = mix(vec3(0.3), vec3(0.4, 0.4, 0.4), step(35, mod(outRoadPos.y, 70.0)));
  col = mix(road_col, vec3(1.0), intensity);

  fragColor = vec4(col, 1.0);
  //fragColor = vec4(1.0,0.0,0.0, 1.0);
  //fragColor = vec4(outColor, 1.0);
}
