;
; An example OpenGL program
; Uses SDL3 and OpenGL to draw a triangle
;
; Author: Ziga Lenarcic
;

(load-file "sdl3.lisp")

;(load-file "gl.lisp")

(if (== (load-dynamic-library "libGL") 0)
  (load-dynamic-library "opengl32"))

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

/* Matrix Mode */
(define GL_MATRIX_MODE				0x0BA0)
(define GL_MODELVIEW				0x1700)
(define GL_PROJECTION				0x1701)
(define GL_TEXTURE				0x1702)

(define-c glClearColor void float float float float)
(define-c glOrtho void double double double double double double)
(define-c glVertex3f void float float float)
(define-c glColor3f void float float float)
(define-c glTranslated void double double double)

;; Program

(SDL_Init SDL_INIT_VIDEO)

(define width 800)
(define height 600)

(define w (SDL_CreateWindow "Hello OpenGL Triangle" width height SDL_WINDOW_OPENGL))

(define gl_context (SDL_GL_CreateContext w))

(glViewport 0 0 width height)

(glMatrixMode GL_PROJECTION)
(glLoadIdentity)
(glOrtho -1.0 1.0 -1.0 1.0 -100.0 100.0)

(glClearColor 0.0 0.0 0.0 1.0)
(glClear GL_COLOR_BUFFER_BIT)

(glMatrixMode GL_MODELVIEW)
(glLoadIdentity)

(glTranslated 0.0 -0.3 0.0)

(glBegin GL_TRIANGLES)
(glColor3f 0.0 0.0 1.0)
(glVertex3f 0.5 0.0 0.0)
(glColor3f 0.0 1.0 0.0)
(glVertex3f 0.0 1.0 0.0)
(glColor3f 1.0 0.0 0.0)
(glVertex3f -0.5 0.0 0.0)
(glEnd)

(SDL_GL_SwapWindow w)

(SDL_Delay 4000)

(SDL_DestroyWindow w)
(SDL_Quit)

