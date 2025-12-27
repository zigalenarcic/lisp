#version 330

layout(location = 0) in vec3 aPosition;

uniform mat4 projection_matrix;
uniform mat4 camera_matrix;
uniform mat4 model_matrix;

void main()
{
  /* default clip space is -1 .. 1 for all axes */

  vec4 point = vec4(aPosition.xy * 0.9, 1.0, 1.0);

  //gl_Position = projection_matrix * camera_matrix * model_matrix * point;
  gl_Position = point;
}
