#version 330

layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec3 aColor;

uniform mat4 projection_matrix;
uniform mat4 view_matrix;
uniform mat4 model_matrix;

out vec3 outColor;
out vec3 outNormal;
out vec3 outPosition;

void main()
{
  /* default clip space is -1 .. 1 for all axes */

  vec4 point = vec4(aPosition, 1.0);

  outColor = aColor;
  outNormal = aNormal;
  outPosition = aPosition;

  gl_Position = projection_matrix * view_matrix * model_matrix * point;
  //gl_Position = vec4(aPosition.xy * 0.4, 1.0, 1.0);
}
