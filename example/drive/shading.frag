#version 330

#define RGB(r, g, b) vec3(r * 0.00392156862, g * 0.00392156862, b * 0.00392156862)

in vec3 outColor;
in vec3 outNormal;
in vec3 outPosition;
out vec4 fragColor;

uniform vec3 camera_position;
uniform vec2 sun_position;
uniform vec3 sun_direction;

void main()
{
  vec3 lightcolor = vec3(1.0, 0.3, 0.3);
  //vec3 lightdir = normalize(vec3(0.0, 0.3, 1.0));
  vec3 lightdir = sun_direction;

  vec3 normal = normalize(outNormal);
  //vec3 normal = outNormal;
  //vec3 col = vec3(1.0, 0.4, 0.0);
  //fragColor = vec4(col, 1.0);

  //fragColor = vec4(outColor, 1.0);
  //fragColor = vec4(normal, 1.0);

  float LN = dot(lightdir, normal);

  vec3 col = 0.1 * outColor; /* ambient */
  col += clamp(LN, 0.0, 1.0) * lightcolor; /* diffuse */

  if (LN > 0.0) /* only on surfaces turned toward light */
  {
    vec3 reflected_part = normal * dot(lightdir, normal);
    vec3 reflected = 2 * reflected_part - lightdir;
    vec3 to_camera = normalize(camera_position - outPosition);

    /* specular */
    //col += pow(clamp(dot(normal, normalize(lightdir + to_camera)), 0.0, 1.0), 400.0) * vec3(1.0, 1.0, 0.0);
    //col += step(0.7, pow(clamp(dot(reflected, to_camera), 0.0, 1.0), 400.0)) * vec3(1.0, 1.0, 0.0);
    //col += pow(clamp(dot(reflected, to_camera), 0.0, 1.0), 800.0) * vec3(1.0, 1.0, 0.0);
  }

  // fog
  vec3 fog_color = RGB(0x9B, 0x8D, 0xA4); //vec3(0.4, 0.4, 0.4);
  col = mix(fog_color, abs(col), clamp(1 - outPosition.z * 0.0003, 0, 1));

  fragColor = vec4(col, 1.0);
}
