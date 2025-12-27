;
; An example OpenGL program
; Uses SDL3 and OpenGL 3 to draw a triangle
;
; Author: Ziga Lenarcic
;

(if (== (load-dynamic-library "libSDL3") 0)
  (load-dynamic-library "SDL3"))

(if (== (load-dynamic-library "libGL") 0)
  (load-dynamic-library "opengl32"))

(define SDL_INIT_AUDIO      0x00000010) /**< `SDL_INIT_AUDIO` implies `SDL_INIT_EVENTS` */
(define SDL_INIT_VIDEO      0x00000020) /**< `SDL_INIT_VIDEO` implies `SDL_INIT_EVENTS`, should be initialized on the main thread */
(define SDL_INIT_JOYSTICK   0x00000200) /**< `SDL_INIT_JOYSTICK` implies `SDL_INIT_EVENTS` */
(define SDL_INIT_HAPTIC     0x00001000)
(define SDL_INIT_GAMEPAD    0x00002000) /**< `SDL_INIT_GAMEPAD` implies `SDL_INIT_JOYSTICK` */
(define SDL_INIT_EVENTS     0x00004000)
(define SDL_INIT_SENSOR     0x00008000) /**< `SDL_INIT_SENSOR` implies `SDL_INIT_EVENTS` */
(define SDL_INIT_CAMERA     0x00010000) /**< `SDL_INIT_CAMERA` implies `SDL_INIT_EVENTS` */


/* SDL_WindowFlags */
(define SDL_WINDOW_FULLSCREEN           0x0000000000000001)    /**< window is in fullscreen mode */
(define SDL_WINDOW_OPENGL               0x0000000000000002)    /**< window usable with OpenGL context */
(define SDL_WINDOW_OCCLUDED             0x0000000000000004)    /**< window is occluded */
(define SDL_WINDOW_HIDDEN               0x0000000000000008)    /**< window is neither mapped onto the desktop nor shown in the taskbar/dock/window list; SDL_ShowWindow() is required for it to become visible */
(define SDL_WINDOW_BORDERLESS           0x0000000000000010)    /**< no window decoration */
(define SDL_WINDOW_RESIZABLE            0x0000000000000020)    /**< window can be resized */
(define SDL_WINDOW_MINIMIZED            0x0000000000000040)    /**< window is minimized */
(define SDL_WINDOW_MAXIMIZED            0x0000000000000080)    /**< window is maximized */
(define SDL_WINDOW_MOUSE_GRABBED        0x0000000000000100)    /**< window has grabbed mouse input */
(define SDL_WINDOW_INPUT_FOCUS          0x0000000000000200)    /**< window has input focus */
(define SDL_WINDOW_MOUSE_FOCUS          0x0000000000000400)    /**< window has mouse focus */
(define SDL_WINDOW_EXTERNAL             0x0000000000000800)    /**< window not created by SDL */
(define SDL_WINDOW_MODAL                0x0000000000001000)    /**< window is modal */
(define SDL_WINDOW_HIGH_PIXEL_DENSITY   0x0000000000002000)    /**< window uses high pixel density back buffer if possible */
(define SDL_WINDOW_MOUSE_CAPTURE        0x0000000000004000)    /**< window has mouse captured (unrelated to MOUSE_GRABBED) */
(define SDL_WINDOW_MOUSE_RELATIVE_MODE  0x0000000000008000)    /**< window has relative mode enabled */
(define SDL_WINDOW_ALWAYS_ON_TOP        0x0000000000010000)    /**< window should always be above others */
(define SDL_WINDOW_UTILITY              0x0000000000020000)    /**< window should be treated as a utility window, not showing in the task bar and window list */
(define SDL_WINDOW_TOOLTIP              0x0000000000040000)    /**< window should be treated as a tooltip and does not get mouse or keyboard focus, requires a parent window */
(define SDL_WINDOW_POPUP_MENU           0x0000000000080000)    /**< window should be treated as a popup menu, requires a parent window */
(define SDL_WINDOW_KEYBOARD_GRABBED     0x0000000000100000)    /**< window has grabbed keyboard input */
(define SDL_WINDOW_VULKAN               0x0000000010000000)    /**< window usable for Vulkan surface */
(define SDL_WINDOW_METAL                0x0000000020000000)    /**< window usable for Metal view */
(define SDL_WINDOW_TRANSPARENT          0x0000000040000000)    /**< window with transparent buffer */
(define SDL_WINDOW_NOT_FOCUSABLE        0x0000000080000000)    /**< window should not be focusable */


(define SDL_PIXELFORMAT_XRGB8888 0x16161804) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_XRGB, SDL_PACKEDLAYOUT_8888, 24, 4), */
(define SDL_PIXELFORMAT_RGBX8888 0x16261804) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_RGBX, SDL_PACKEDLAYOUT_8888, 24, 4), */
(define SDL_PIXELFORMAT_XBGR8888 0x16561804) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_XBGR, SDL_PACKEDLAYOUT_8888, 24, 4), */
(define SDL_PIXELFORMAT_BGRX8888 0x16661804) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_BGRX, SDL_PACKEDLAYOUT_8888, 24, 4), */
(define SDL_PIXELFORMAT_ARGB8888 0x16362004) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_ARGB, SDL_PACKEDLAYOUT_8888, 32, 4), */
(define SDL_PIXELFORMAT_RGBA8888 0x16462004) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_RGBA, SDL_PACKEDLAYOUT_8888, 32, 4), */
(define SDL_PIXELFORMAT_ABGR8888 0x16762004) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_ABGR, SDL_PACKEDLAYOUT_8888, 32, 4), */
(define SDL_PIXELFORMAT_BGRA8888 0x16862004) /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_BGRA, SDL_PACKEDLAYOUT_8888, 32, 4), */

(define SDL_GL_RED_SIZE 0)                    /**< the minimum number of bits for the red channel of the color buffer; defaults to 8. */
(define SDL_GL_GREEN_SIZE 1)                  /**< the minimum number of bits for the green channel of the color buffer; defaults to 8. */
(define SDL_GL_BLUE_SIZE 2)                   /**< the minimum number of bits for the blue channel of the color buffer; defaults to 8. */
(define SDL_GL_ALPHA_SIZE 3)                  /**< the minimum number of bits for the alpha channel of the color buffer; defaults to 8. */
(define SDL_GL_BUFFER_SIZE 4)                 /**< the minimum number of bits for frame buffer size; defaults to 0. */
(define SDL_GL_DOUBLEBUFFER 5)                /**< whether the output is single or double buffered; defaults to double buffering on. */
(define SDL_GL_DEPTH_SIZE 6)                  /**< the minimum number of bits in the depth buffer; defaults to 16. */
(define SDL_GL_STENCIL_SIZE 7)                /**< the minimum number of bits in the stencil buffer; defaults to 0. */
(define SDL_GL_ACCUM_RED_SIZE 8)              /**< the minimum number of bits for the red channel of the accumulation buffer; defaults to 0. */
(define SDL_GL_ACCUM_GREEN_SIZE 9)            /**< the minimum number of bits for the green channel of the accumulation buffer; defaults to 0. */
(define SDL_GL_ACCUM_BLUE_SIZE 10)             /**< the minimum number of bits for the blue channel of the accumulation buffer; defaults to 0. */
(define SDL_GL_ACCUM_ALPHA_SIZE 11)            /**< the minimum number of bits for the alpha channel of the accumulation buffer; defaults to 0. */
(define SDL_GL_STEREO 12)                      /**< whether the output is stereo 3D; defaults to off. */
(define SDL_GL_MULTISAMPLEBUFFERS 13)          /**< the number of buffers used for multisample anti-aliasing; defaults to 0. */
(define SDL_GL_MULTISAMPLESAMPLES 14)          /**< the number of samples used around the current pixel used for multisample anti-aliasing. */
(define SDL_GL_ACCELERATED_VISUAL 15)          /**< set to 1 to require hardware acceleration, set to 0 to force software rendering; defaults to allow either. */
(define SDL_GL_RETAINED_BACKING 16)            /**< not used (deprecated). */
(define SDL_GL_CONTEXT_MAJOR_VERSION 17)       /**< OpenGL context major version. */
(define SDL_GL_CONTEXT_MINOR_VERSION 18)       /**< OpenGL context minor version. */
(define SDL_GL_CONTEXT_FLAGS 19)               /**< some combination of 0 or more of elements of the SDL_GLContextFlag enumeration; defaults to 0. */
(define SDL_GL_CONTEXT_PROFILE_MASK 20)        /**< type of GL context (Core, Compatibility, ES). See SDL_GLProfile; default value depends on platform. */
(define SDL_GL_SHARE_WITH_CURRENT_CONTEXT 21)  /**< OpenGL context sharing; defaults to 0. */
(define SDL_GL_FRAMEBUFFER_SRGB_CAPABLE 22)    /**< requests sRGB capable visual; defaults to 0. */
(define SDL_GL_CONTEXT_RELEASE_BEHAVIOR 23)    /**< sets context the release behavior. See SDL_GLContextReleaseFlag; defaults to FLUSH. */
(define SDL_GL_CONTEXT_RESET_NOTIFICATION 24)  /**< set context reset notification. See SDL_GLContextResetNotification; defaults to NO_NOTIFICATION. */
(define SDL_GL_CONTEXT_NO_ERROR 25)
(define SDL_GL_FLOATBUFFERS 26)
(define SDL_GL_EGL_PLATFORM 27)

(define SDL_EVENT_QUIT            0x100) /**< User-requested quit */

/* Boolean values */
(define GL_FALSE				0)
(define GL_TRUE					1)

/* Data types */
(define GL_BYTE					0x1400)
(define GL_UNSIGNED_BYTE			0x1401)
(define GL_SHORT				0x1402)
(define GL_UNSIGNED_SHORT			0x1403)
(define GL_INT					0x1404)
(define GL_UNSIGNED_INT				0x1405)
(define GL_FLOAT				0x1406)
(define GL_2_BYTES				0x1407)
(define GL_3_BYTES				0x1408)
(define GL_4_BYTES				0x1409)
(define GL_DOUBLE				0x140A)

/* Primitives */
(define GL_POINTS				0x0000)
(define GL_LINES				0x0001)
(define GL_LINE_LOOP				0x0002)
(define GL_LINE_STRIP				0x0003)
(define GL_TRIANGLES				0x0004)
(define GL_TRIANGLE_STRIP			0x0005)
(define GL_TRIANGLE_FAN				0x0006)
(define GL_QUADS				0x0007)
(define GL_QUAD_STRIP				0x0008)
(define GL_POLYGON				0x0009)

/* Vertex Arrays */
(define GL_VERTEX_ARRAY				0x8074)
(define GL_NORMAL_ARRAY				0x8075)
(define GL_COLOR_ARRAY				0x8076)
(define GL_INDEX_ARRAY				0x8077)
(define GL_TEXTURE_COORD_ARRAY			0x8078)
(define GL_EDGE_FLAG_ARRAY			0x8079)
(define GL_VERTEX_ARRAY_SIZE			0x807A)
(define GL_VERTEX_ARRAY_TYPE			0x807B)
(define GL_VERTEX_ARRAY_STRIDE			0x807C)
(define GL_NORMAL_ARRAY_TYPE			0x807E)
(define GL_NORMAL_ARRAY_STRIDE			0x807F)
(define GL_COLOR_ARRAY_SIZE			0x8081)
(define GL_COLOR_ARRAY_TYPE			0x8082)
(define GL_COLOR_ARRAY_STRIDE			0x8083)
(define GL_INDEX_ARRAY_TYPE			0x8085)
(define GL_INDEX_ARRAY_STRIDE			0x8086)
(define GL_TEXTURE_COORD_ARRAY_SIZE		0x8088)
(define GL_TEXTURE_COORD_ARRAY_TYPE		0x8089)
(define GL_TEXTURE_COORD_ARRAY_STRIDE		0x808A)
(define GL_EDGE_FLAG_ARRAY_STRIDE		0x808C)
(define GL_VERTEX_ARRAY_POINTER			0x808E)
(define GL_NORMAL_ARRAY_POINTER			0x808F)
(define GL_COLOR_ARRAY_POINTER			0x8090)
(define GL_INDEX_ARRAY_POINTER			0x8091)
(define GL_TEXTURE_COORD_ARRAY_POINTER		0x8092)
(define GL_EDGE_FLAG_ARRAY_POINTER		0x8093)

/* Utility */
(define GL_VENDOR				0x1F00)
(define GL_RENDERER				0x1F01)
(define GL_VERSION				0x1F02)
(define GL_EXTENSIONS				0x1F03)

/* Errors */
(define GL_NO_ERROR 				0)
(define GL_INVALID_ENUM				0x0500)
(define GL_INVALID_VALUE			0x0501)
(define GL_INVALID_OPERATION			0x0502)
(define GL_STACK_OVERFLOW			0x0503)
(define GL_STACK_UNDERFLOW			0x0504)
(define GL_OUT_OF_MEMORY			0x0505)

/* glPush/PopAttrib bits */
(define GL_CURRENT_BIT				0x00000001)
(define GL_POINT_BIT				0x00000002)
(define GL_LINE_BIT				0x00000004)
(define GL_POLYGON_BIT				0x00000008)
(define GL_POLYGON_STIPPLE_BIT			0x00000010)
(define GL_PIXEL_MODE_BIT			0x00000020)
(define GL_LIGHTING_BIT				0x00000040)
(define GL_FOG_BIT				0x00000080)
(define GL_DEPTH_BUFFER_BIT			0x00000100)
(define GL_ACCUM_BUFFER_BIT			0x00000200)
(define GL_STENCIL_BUFFER_BIT			0x00000400)
(define GL_VIEWPORT_BIT				0x00000800)
(define GL_TRANSFORM_BIT			0x00001000)
(define GL_ENABLE_BIT				0x00002000)
(define GL_COLOR_BUFFER_BIT			0x00004000)
(define GL_HINT_BIT				0x00008000)
(define GL_EVAL_BIT				0x00010000)
(define GL_LIST_BIT				0x00020000)
(define GL_TEXTURE_BIT				0x00040000)
(define GL_SCISSOR_BIT				0x00080000)
(define GL_ALL_ATTRIB_BITS			0xFFFFFFFF)

/* Matrix Mode */
(define GL_MATRIX_MODE				0x0BA0)
(define GL_MODELVIEW				0x1700)
(define GL_PROJECTION				0x1701)
(define GL_TEXTURE				0x1702)

/* Blending */
(define GL_BLEND				0x0BE2)
(define GL_BLEND_SRC				0x0BE1)
(define GL_BLEND_DST				0x0BE0)
(define GL_ZERO					0)
(define GL_ONE					1)
(define GL_SRC_COLOR				0x0300)
(define GL_ONE_MINUS_SRC_COLOR			0x0301)
(define GL_SRC_ALPHA				0x0302)
(define GL_ONE_MINUS_SRC_ALPHA			0x0303)
(define GL_DST_ALPHA				0x0304)
(define GL_ONE_MINUS_DST_ALPHA			0x0305)
(define GL_DST_COLOR				0x0306)
(define GL_ONE_MINUS_DST_COLOR			0x0307)
(define GL_SRC_ALPHA_SATURATE			0x0308)


/* Depth buffer */
(define GL_NEVER				0x0200)
(define GL_LESS					0x0201)
(define GL_EQUAL				0x0202)
(define GL_LEQUAL				0x0203)
(define GL_GREATER				0x0204)
(define GL_NOTEQUAL				0x0205)
(define GL_GEQUAL				0x0206)
(define GL_ALWAYS				0x0207)
(define GL_DEPTH_TEST				0x0B71)
(define GL_DEPTH_BITS				0x0D56)
(define GL_DEPTH_CLEAR_VALUE			0x0B73)
(define GL_DEPTH_FUNC				0x0B74)
(define GL_DEPTH_RANGE				0x0B70)
(define GL_DEPTH_WRITEMASK			0x0B72)
(define GL_DEPTH_COMPONENT			0x1902)

/* Polygons */
(define GL_POINT				0x1B00)
(define GL_LINE					0x1B01)
(define GL_FILL					0x1B02)
(define GL_CW					0x0900)
(define GL_CCW					0x0901)
(define GL_FRONT				0x0404)
(define GL_BACK					0x0405)
(define GL_POLYGON_MODE				0x0B40)
(define GL_POLYGON_SMOOTH			0x0B41)
(define GL_POLYGON_STIPPLE			0x0B42)
(define GL_EDGE_FLAG				0x0B43)
(define GL_CULL_FACE				0x0B44)
(define GL_CULL_FACE_MODE			0x0B45)
(define GL_FRONT_FACE				0x0B46)
(define GL_POLYGON_OFFSET_FACTOR		0x8038)
(define GL_POLYGON_OFFSET_UNITS			0x2A00)
(define GL_POLYGON_OFFSET_POINT			0x2A01)
(define GL_POLYGON_OFFSET_LINE			0x2A02)
(define GL_POLYGON_OFFSET_FILL			0x8037)

(define GL_ARRAY_BUFFER                   0x8892)

(define GL_STREAM_DRAW                    0x88E0)
(define GL_STREAM_READ                    0x88E1)
(define GL_STREAM_COPY                    0x88E2)
(define GL_STATIC_DRAW                    0x88E4)
(define GL_STATIC_READ                    0x88E5)
(define GL_STATIC_COPY                    0x88E6)
(define GL_DYNAMIC_DRAW                   0x88E8)
(define GL_DYNAMIC_READ                   0x88E9)
(define GL_DYNAMIC_COPY                   0x88EA)

(define GL_COMPILE_STATUS                 0x8B81)
(define GL_LINK_STATUS                    0x8B82)
(define GL_VALIDATE_STATUS                0x8B83)

(define-c glClearColor void float float float float)
(define-c glOrtho void double double double double double double)
(define-c glVertex3f void float float float)
(define-c glVertex3d void double double double)
(define-c glColor3f void float float float)
(define-c glScaled void double double double)
(define-c glTranslated void double double double)
(define-c glRotated void double double double double)
(define-c glFrustum void double double double double double double)
(define-c glDrawArrays void ulong ulong ulong)

; OpenGL 2.0

(define GL_FRAGMENT_SHADER                0x8B30)
(define GL_VERTEX_SHADER                  0x8B31)

(comment
(define-c glCreateShader ulong ulong)
(define-c glCompileShader void ulong)
(define-c glShaderSource void ulong ulong ulong ulong)

(define-c glCreateProgram ulong)
(define-c glAttachShader void ulong ulong)
(define-c glLinkProgram void ulong)

(define-c glUseProgram void ulong)

(define-c glBindBuffer void ulong ulong)
(define-c glVertexAttribPointer void ulong ulong ulong ulong ulong ulong)
(define-c glEnableVertexAttribArray void ulong)

(define-c glGetUniformLocation ulong ulong ptr)

(define-c glUniform1f void ulong float)
(define-c glUniform2f void ulong float float)
(define-c glUniform3f void ulong float float float)
(define-c glUniform4f void ulong float float float float)

(define-c glBufferData void ulong ulong ptr ulong)
)

(define-c (glCreateShader) ulong ulong)
(define-c (glCompileShader) void ulong)
(define-c (glShaderSource) void ulong ulong ulong ulong)

(define-c (glCreateProgram) ulong)
(define-c (glAttachShader) void ulong ulong)
(define-c (glLinkProgram) void ulong)

(define-c (glUseProgram) void ulong)

(define-c (glBindBuffer) void ulong ulong)
(define-c (glVertexAttribPointer) void ulong ulong ulong ulong ulong ulong)
(define-c (glEnableVertexAttribArray) void ulong)
(define-c (glBindVertexArray) void ulong)

(define-c (glGetUniformLocation) ulong ulong ptr)

(define-c (glUniform1f) void ulong float)
(define-c (glUniform2f) void ulong float float)
(define-c (glUniform3f) void ulong float float float)
(define-c (glUniform4f) void ulong float float float float)

(define-c (glBufferData) void ulong ulong ptr ulong)

(define-c (glGetProgramiv) void ulong ulong ptr)
(define-c (glGenBuffers) void ulong ptr)
(define-c (glGenVertexArrays) void ulong ptr)

;; Program

(define width 800)
(define height 600)

(SDL_Init SDL_INIT_VIDEO)

(SDL_GL_SetAttribute SDL_GL_CONTEXT_MAJOR_VERSION 3)
(SDL_GL_SetAttribute SDL_GL_CONTEXT_MINOR_VERSION 3)

(SDL_GL_SetAttribute SDL_GL_RED_SIZE 8)
(SDL_GL_SetAttribute SDL_GL_GREEN_SIZE 8)
(SDL_GL_SetAttribute SDL_GL_BLUE_SIZE 8)
(SDL_GL_SetAttribute SDL_GL_DEPTH_SIZE 16)
(SDL_GL_SetAttribute SDL_GL_DOUBLEBUFFER 1)

(define w (SDL_CreateWindow "Hello OpenGL 3 Triangle" width height SDL_WINDOW_OPENGL))

(define gl_context (SDL_GL_CreateContext w))

(define (get-gl-function name)
  (let addr (get-function-pointer name))
  (if (!= addr 0)
    addr
    (wglGetProcAddress name)))

(set-function-pointer (quote glCompileShader) (wglGetProcAddress "glCompileShader"))

(set-function-pointer (quote glCreateShader) (wglGetProcAddress "glCreateShader"))
(set-function-pointer (quote glCompileShader) (wglGetProcAddress "glCompileShader"))
(set-function-pointer (quote glShaderSource) (wglGetProcAddress "glShaderSource"))

(set-function-pointer (quote glCreateProgram) (wglGetProcAddress "glCreateProgram"))
(set-function-pointer (quote glAttachShader) (wglGetProcAddress "glAttachShader"))
(set-function-pointer (quote glLinkProgram) (wglGetProcAddress "glLinkProgram"))

(set-function-pointer (quote glUseProgram) (wglGetProcAddress "glUseProgram"))

(set-function-pointer (quote glBindBuffer) (wglGetProcAddress "glBindBuffer"))
(set-function-pointer (quote glVertexAttribPointer) (wglGetProcAddress "glVertexAttribPointer"))
(set-function-pointer (quote glEnableVertexAttribArray) (wglGetProcAddress "glEnableVertexAttribArray"))
(set-function-pointer (quote glBindVertexArray) (wglGetProcAddress "glBindVertexArray"))

(set-function-pointer (quote glGetUniformLocation) (wglGetProcAddress "glGetUniformLocation"))

(set-function-pointer (quote glUniform1f) (wglGetProcAddress "glUniform1f"))
(set-function-pointer (quote glUniform2f) (wglGetProcAddress "glUniform2f"))
(set-function-pointer (quote glUniform3f) (wglGetProcAddress "glUniform3f"))
(set-function-pointer (quote glUniform4f) (wglGetProcAddress "glUniform4f"))

(set-function-pointer (quote glBufferData) (wglGetProcAddress "glBufferData"))

(set-function-pointer (quote glGetProgramiv) (wglGetProcAddress "glGetProgramiv"))
(set-function-pointer (quote glGenBuffers) (wglGetProcAddress "glGenBuffers"))
(set-function-pointer (quote glGenVertexArrays) (wglGetProcAddress "glGenVertexArrays"))

(define vertex-shader
"#version 330

layout(location = 0) in vec3 pos;

void main()
{
  gl_Position = vec4(pos.xy, 0.0 , 1.0);
}")

(define frag-shader
"#version 330

out vec4 out_color;
uniform float red_level;

void main()
{
  vec3 col = vec3(red_level, 0.4, 0.4);

  out_color = vec4(col, 1.0);
}")

(define shader-program)

(define points-array (make-array 9 "f4"))

(set points-array[0] -0.5)
(set points-array[1] -0.5)
(set points-array[2] -3.0)

(set points-array[3] 0.5)
(set points-array[4] -0.5)
(set points-array[5] -3.0)

(set points-array[6] 0.0)
(set points-array[7] 0.5)
(set points-array[8] -3.0)

(define vbo-points)
(define vertex-arr)
(define level 0.0)
(define direction 1.0)

(define (render)
  (glClearColor 0.3 0.3 0.3 1.0)
  (glClear (+ GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT))

  (if shader-program
    (do

      (set level (+ level direction))
      (if (== level 100.0) (set direction -1.0))
      (if (== level 0.0) (set direction 1.0))

      (glUseProgram shader-program)

      (glUniform1f (glGetUniformLocation shader-program "red_level") (/ level 100.0))

      (glBindBuffer GL_ARRAY_BUFFER vbo-points)
      (glBindVertexArray vertex-arr)

      (glEnableVertexAttribArray 0)
      (glVertexAttribPointer 0 3 GL_FLOAT GL_FALSE 0 0)

      (glDrawArrays GL_TRIANGLES 0 3)

      (glBindVertexArray 0)

      (glUseProgram 0)))


  (SDL_GL_SwapWindow w))

(define (load-shader vs-source fs-source)
  (let vs (glCreateShader GL_VERTEX_SHADER))
  (let fs (glCreateShader GL_FRAGMENT_SHADER))
  (let p (glCreateProgram))
  (let tmp-int (make-array 30 "i4"))

  (glShaderSource vs 1 (address-of-storage vs-source) 0)
  (glCompileShader vs)

  (glShaderSource fs 1 (address-of-storage fs-source) 0)
  (glCompileShader fs)

  (glAttachShader p vs)
  (glAttachShader p fs)
  (glLinkProgram p)

  (glGetProgramiv p GL_LINK_STATUS tmp-int)
  (print "Program link status " tmp-int[0] "\n")

  p
  )

(define (main)

  (print "Opengl vendor " (string-from-c-pointer (glGetString GL_VENDOR)) "\n")
  (print "Opengl version " (string-from-c-pointer (glGetString GL_VERSION)) "\n")

  (glEnable GL_DEPTH_TEST)
  (glDepthFunc GL_LESS)

  (glViewport 0 0 width height)
  (glMatrixMode GL_PROJECTION)
  (glLoadIdentity)
  (glMatrixMode GL_MODELVIEW)
  (glLoadIdentity)

  (set shader-program (load-shader vertex-shader frag-shader))

  (print "Shader " shader-program "\n")

  (do
    (let vbo (make-array 1 "u4"))
    (glGenBuffers 1 vbo)
    (set vbo-points vbo[0])
    (print "vbo " vbo-points "\n")
    (glBindBuffer GL_ARRAY_BUFFER vbo-points)
    (glBufferData GL_ARRAY_BUFFER (* (len points-array) 4) points-array GL_STATIC_DRAW)

    (glGenVertexArrays 1 vbo)
    (set vertex-arr vbo[0])

    (glBindBuffer GL_ARRAY_BUFFER 0))

    (let ev-storage (make-array 60 "i4"))
  (with-loop
             (SDL_PollEvent ev-storage)

             (if (== ev-storage[0] SDL_EVENT_QUIT)
               (quit 0))

             (render)

             (next-loop))


  //(SDL_GL_DeleteContext gl_context)
  (SDL_DestroyWindow w)
  (SDL_Quit))

(main)

