#version 330

layout(location = 0) in vec3 aPosition;

void main()
{
  /* default clip space is -1 .. 1 for all axes */
  //gl_Position = projection_matrix * view_matrix * vec4(aPosition, 1.0);
  gl_Position = vec4(aPosition.xy, 1.0, 1.0); /* if we're using -1..1 quad, no need to transform it, fix z at 1.0 */
}
