#version 330

layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec3 aColor;
layout(location = 3) in vec2 road_pos;

uniform mat4 projection_matrix;
uniform mat4 view_matrix;
uniform mat4 model_matrix;

out vec3 outPosition;
out vec3 outNormal;
out vec3 outColor;
out vec2 outRoadPos;

void main()
{
  /* default clip space is -1 .. 1 for all axes */

  vec4 point = vec4(aPosition, 1.0);

  outColor = aColor;
  outNormal = aNormal; /* interpolate normal data */
  outRoadPos = road_pos;

  vec4 pos = projection_matrix * view_matrix * model_matrix * point;
  outPosition = pos.xyz;
  gl_Position = pos;
  //gl_Position = vec4(aPosition.xy * 0.4, 1.0, 1.0);
}
