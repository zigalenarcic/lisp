#version 330

layout(location = 0) in vec3 aPosition;

out vec2 vTexCoord;

void main()
{
  /* default clip space is -1 .. 1 for all axes */
  vec4 point = vec4(aPosition.xy, -1.0, 1.0);

  vTexCoord = 0.5 * (aPosition.xy + 1.0); // quad is -1 .. 1, -1 .. 1, texture 0 .. 1, 0 .. 1

  gl_Position = point;
}
