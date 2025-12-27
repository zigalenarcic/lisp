;
; An example OpenGL program
; Uses SDL3 and OpenGL 3 to draw a triangle
;
; Author: Ziga Lenarcic
;

(load-file "../sdl3.lisp")
(load-file "../gl.lisp")

(define width 800)
(define height 600)

(define up-sample-ratio 1)
(define render-width (* up-sample-ratio width))
(define render-height (* up-sample-ratio height))

(SDL_Init SDL_INIT_VIDEO)

(SDL_GL_SetAttribute SDL_GL_CONTEXT_MAJOR_VERSION 3)
(SDL_GL_SetAttribute SDL_GL_CONTEXT_MINOR_VERSION 3)

;(SDL_GL_SetAttribute SDL_GL_MULTISAMPLEBUFFERS 1)
;(SDL_GL_SetAttribute SDL_GL_MULTISAMPLESAMPLES 8)

(SDL_GL_SetAttribute SDL_GL_RED_SIZE 8)
(SDL_GL_SetAttribute SDL_GL_GREEN_SIZE 8)
(SDL_GL_SetAttribute SDL_GL_BLUE_SIZE 8)
(SDL_GL_SetAttribute SDL_GL_DEPTH_SIZE 16)
(SDL_GL_SetAttribute SDL_GL_DOUBLEBUFFER 1)

(define w (SDL_CreateWindow "Hello Drive" width height SDL_WINDOW_OPENGL))

(define gl_context (SDL_GL_CreateContext w))

(init-gl-functions)

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

(define shader-normal)
(define shader-quad)
(define shader-sky)
(define shader-road)

(define fovy 60.0)

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

(define points-array (make-array 9 "f4"))

(set points-array[0] -0.5)
(set points-array[1] -0.5)
(set points-array[2] 0.0)

(set points-array[3] 0.5)
(set points-array[4] -0.5)
(set points-array[5] 0.0)

(set points-array[6] 0.0)
(set points-array[7] 0.5)
(set points-array[8] 0.0)

(define vertex-arr)

(define vertex-arr-road)

(define vertex-arr-quad)

(define vertex-arr-sky)

(define keys (make-array 20))

(define pi 3.1415926535897932)
(define degrees-to-radians (* pi (/ 1.0 180.0)))
(define radians-to-degrees (* 180.0 (/ 1.0 pi)))

;;
;; Coordinate system definition:
;; We follow OpenGL clip space coordinate system
;; Right handed, positive Y is up.
;;
;; Yaw = 0, view is looking along -Z axis
;;
;; Camera angles:
;; Yaw - angle between camera and -Z axis, rotation around Y
;; Pitch - angle between camera and X-Z horizontal world plane, positive looking up
;; Roll - angle along camera axis between Y world axis and camera's up axis,
;;   positive value rotates the camera clockwise along the view vector (-Z camera's axis)
;;
(define camera-pos (make-array 3 "f4"))
(set camera-pos[1] 18.0) ; begin by camera being at 18.0 height at X = 0, Z = 0
(define camera-angles (make-array 3 "f4"))
(set camera-angles[0] pi) ; begin by looking at the +Z axis with +X on the left

(define sun-pos (make-array 2 "f4" pi 0.2)) ;; phi, theta

(define level 0.0)
(define direction 1.0)

(define (clamp x xmin xmax)
  (if (< x xmin) xmin
    (if (> x xmax)
      xmax
      x)))

(define (make-identity n)
  (let a (make-array (* n n) "f4"))
  (for (i n)
       (set a[(+ (* i n) i)] 1.0)
       )
  a)

(define (mat4-multiply c a b)
  (let c0  (+ (* a[0] b[0]) (* a[1] b[4]) (* a[2] b[8])  (* a[3] b[12])))
  (let c1  (+ (* a[0] b[1]) (* a[1] b[5]) (* a[2] b[9])  (* a[3] b[13])))
  (let c2  (+ (* a[0] b[2]) (* a[1] b[6]) (* a[2] b[10]) (* a[3] b[14])))
  (let c3  (+ (* a[0] b[3]) (* a[1] b[7]) (* a[2] b[11]) (* a[3] b[15])))

  (let c4  (+ (* a[4] b[0]) (* a[5] b[4]) (* a[6] b[8])  (* a[7] b[12])))
  (let c5  (+ (* a[4] b[1]) (* a[5] b[5]) (* a[6] b[9])  (* a[7] b[13])))
  (let c6  (+ (* a[4] b[2]) (* a[5] b[6]) (* a[6] b[10]) (* a[7] b[14])))
  (let c7  (+ (* a[4] b[3]) (* a[5] b[7]) (* a[6] b[11]) (* a[7] b[15])))

  (let c8  (+ (* a[8] b[0]) (* a[9] b[4]) (* a[10] b[8])  (* a[11] b[12])))
  (let c9  (+ (* a[8] b[1]) (* a[9] b[5]) (* a[10] b[9])  (* a[11] b[13])))
  (let c10 (+ (* a[8] b[2]) (* a[9] b[6]) (* a[10] b[10]) (* a[11] b[14])))
  (let c11 (+ (* a[8] b[3]) (* a[9] b[7]) (* a[10] b[11]) (* a[11] b[15])))

  (let c12 (+ (* a[12] b[0]) (* a[13] b[4]) (* a[14] b[8])  (* a[15] b[12])))
  (let c13 (+ (* a[12] b[1]) (* a[13] b[5]) (* a[14] b[9])  (* a[15] b[13])))
  (let c14 (+ (* a[12] b[2]) (* a[13] b[6]) (* a[14] b[10]) (* a[15] b[14])))
  (let c15 (+ (* a[12] b[3]) (* a[13] b[7]) (* a[14] b[11]) (* a[15] b[15])))

  (set c[0]  c0)
  (set c[1]  c1)
  (set c[2]  c2)
  (set c[3]  c3)
  (set c[4]  c4)
  (set c[5]  c5)
  (set c[6]  c6)
  (set c[7]  c7)
  (set c[8]  c8)
  (set c[9]  c9)
  (set c[10] c10)
  (set c[11] c11)
  (set c[12] c12)
  (set c[13] c13)
  (set c[14] c14)
  (set c[15] c15))

(define (mat4-vec-multiply c a b)
  (set c[0] (+ (* a[0] b[0])  (* a[1] b[1])  (* a[2] b[2])   (* a[3] b[3])))
  (set c[1] (+ (* a[4] b[0])  (* a[5] b[1])  (* a[6] b[2])   (* a[7] b[3])))
  (set c[2] (+ (* a[8] b[0])  (* a[9] b[1])  (* a[10] b[2])  (* a[11] b[3])))
  (set c[3] (+ (* a[12] b[0]) (* a[13] b[1]) (* a[14] b[2])  (* a[15] b[3])))
  )

(define (make-projection-matrix c fov-y aspect-ratio near far)
  (let f (/ 1.0 (tan (* 0.5 pi (/ fov-y 180.0)))))

  (set c[0] (/ f aspect-ratio))
  (set c[1] 0.0)
  (set c[2] 0.0)
  (set c[3] 0.0)

  (set c[4] 0.0)
  (set c[5] f)
  (set c[6] 0.0)
  (set c[7] 0.0)

  (set c[8] 0.0)
  (set c[9] 0.0)
  (set c[10] (/ (+ near far) (- near far)))
  (set c[11] (/ (* 2.0 near far) (- near far)))

  (set c[12] 0.0)
  (set c[13] 0.0)
  (set c[14] -1.0)
  (set c[15] 0.0)
  )

(define (make-ortho-projection-matrix c left right bottom top near far)
  (set c[0] (/ 2.0 (- right left)))
  (set c[1] 0.0)
  (set c[2] 0.0)
  (set c[3] (/ (+ left right) (- left right)))

  (set c[4] 0.0)
  (set c[5] (/ 2.0 (- top bottom)))
  (set c[6] 0.0)
  (set c[7] (/ (+ bottom top) (- bottom top)))

  ; z_n = 1/(near - far) * z + near/(near -far)
  (set c[8] 0.0)
  (set c[9] 0.0)
  (set c[10] (/ 2.0 (- near far)))
  (set c[11] (/ (+ near far) (- near far)))

  (set c[12] 0.0)
  (set c[13] 0.0)
  (set c[14] 0.0)
  (set c[15] 1.0)
  )

(define (make-scaling-matrix c sx sy sz)
  (set c[0] sx)
  (set c[1] 0.0)
  (set c[2] 0.0)
  (set c[3] 0.0)

  (set c[4] 0.0)
  (set c[5] sy)
  (set c[6] 0.0)
  (set c[7] 0.0)

  (set c[8] 0.0)
  (set c[9] 0.0)
  (set c[10] sz)
  (set c[11] 0.0)

  (set c[12] 0.0)
  (set c[13] 0.0)
  (set c[14] 0.0)
  (set c[15] 1.0))

(define (make-translation-matrix c tx ty tz)
  (set c[0] 1.0)
  (set c[1] 0.0)
  (set c[2] 0.0)
  (set c[3] tx)

  (set c[4] 0.0)
  (set c[5] 1.0)
  (set c[6] 0.0)
  (set c[7] ty)

  (set c[8] 0.0)
  (set c[9] 0.0)
  (set c[10] 1.0)
  (set c[11] tz)

  (set c[12] 0.0)
  (set c[13] 0.0)
  (set c[14] 0.0)
  (set c[15] 1.0)
  )

(define (make-rotation-matrix c alpha vx vy vz)
  (let salpha (sin alpha))
  (let calpha (cos alpha))
  (let mcalpha (- 1.0 calpha))
  (let norm (/ 1.0 (sqrt (+ (* vx vx) (* vy vy) (* vz vz)))))
  (let nx (* norm vx))
  (let ny (* norm vy))
  (let nz (* norm vz))

  (set c[0] (+ (* nx nx mcalpha) calpha))
  (set c[1] (- (* nx ny mcalpha) (* nz salpha)))
  (set c[2] (+ (* nx nz mcalpha) (* ny salpha)))
  (set c[3] 0.0)

  (set c[4] (+ (* nx ny mcalpha) (* nz salpha)))
  (set c[5] (+ (* ny ny mcalpha) calpha))
  (set c[6] (- (* ny nz mcalpha) (* nx salpha)))
  (set c[7] 0.0)

  (set c[8] (- (* nx nz mcalpha) (* ny salpha)))
  (set c[9] (+ (* ny nz mcalpha) (* nx salpha)))
  (set c[10] (+ (* nz nz mcalpha) calpha))
  (set c[11] 0.0)

  (set c[12] 0.0)
  (set c[13] 0.0)
  (set c[14] 0.0)
  (set c[15] 1.0)
  None
  )

(define projection-matrix (make-identity 4))
(define view-matrix (make-identity 4))
(define view-rotation-matrix (make-identity 4))
(define model-matrix (make-identity 4))
(define temp-matrix (make-identity 4))
(define temp-matrix2 (make-identity 4))
(define temp-matrix3 (make-identity 4))

(define road-vertices)
(define terrain-vertices)

(define road-center)
(define road-direction)
(define road-tangent)

(define road-vertex-arrays (make-array 300 "i4"))
(define road-vertex-arrays-vertex-count (make-array 300 "i4"))
(define road-vertex-arrays-count 0)

(define terrain-vertex-arrays (make-array 300 "i4"))
(define terrain-vertex-arrays-vertex-count (make-array 300 "i4"))

(define line-vertex-arrays (make-array 300 "i4"))
(define line-vertex-arrays-vertex-count (make-array 300 "i4"))

(define sky-vertex-array)
(define sky-vertex-array-count 0)

(define (calculate-normals arr num-numbers vertex-stride)
  (let num-vertices (int/ num-numbers vertex-stride))
  (let num-triangles (int/ num-vertices 3))
  (let triangle-stride (* vertex-stride 3))

  (print "Calulate normals numbers " num-numbers " num vertices " num-vertices " num-triangles " num-triangles "\n")
  (for (i num-triangles)
       (let triangle-offset (* i triangle-stride))
       ;; vec vertex 2 - 1
       (let a1 (- arr[(+ triangle-offset vertex-stride 0)] arr[(+ triangle-offset 0)]))
       (let a2 (- arr[(+ triangle-offset vertex-stride 1)] arr[(+ triangle-offset 1)]))
       (let a3 (- arr[(+ triangle-offset vertex-stride 2)] arr[(+ triangle-offset 2)]))

       (let b1 (- arr[(+ triangle-offset (* 2 vertex-stride) 0)] arr[(+ triangle-offset 0)]))
       (let b2 (- arr[(+ triangle-offset (* 2 vertex-stride) 1)] arr[(+ triangle-offset 1)]))
       (let b3 (- arr[(+ triangle-offset (* 2 vertex-stride) 2)] arr[(+ triangle-offset 2)]))

       (let s1 (- (* a2 b3) (* a3 b2)))
       (let s2 (- (* a3 b1) (* a1 b3)))
       (let s3 (- (* a1 b2) (* a2 b1)))

       (let vec-norm (/ 1.0 (sqrt (+ (* s1 s1) (* s2 s2) (* s3 s3)))))

       (let s1n (* vec-norm s1))
       (let s2n (* vec-norm s2))
       (let s3n (* vec-norm s3))

       ;; set the same normal for all 3 vertices in a triangle
       (set arr[(+ triangle-offset 3)] s1n)
       (set arr[(+ triangle-offset 4)] s2n)
       (set arr[(+ triangle-offset 5)] s3n)

       (set arr[(+ triangle-offset vertex-stride 3)] s1n)
       (set arr[(+ triangle-offset vertex-stride 4)] s2n)
       (set arr[(+ triangle-offset vertex-stride 5)] s3n)

       (set arr[(+ triangle-offset (* 2 vertex-stride) 3)] s1n)
       (set arr[(+ triangle-offset (* 2 vertex-stride) 4)] s2n)
       (set arr[(+ triangle-offset (* 2 vertex-stride) 5)] s3n)
       )
  )
;;
;; Road is made from straight sections with random length
;; and circular (part of circle) sections with random length/angle and radius.
;;
;; Circular sections is described as:
;; l - length of the section, R - radius of the circle, phi - angle which
;; the section makes, alpha - angle between current road angle and short path
;; to end of section, L - length of the short (direct) path to end of section
;;
;; l = R * phi
;; alpha = phi / 2
;; L = 2 * R * sin(phi / 2)
;; Point on circular path for angle phi' = n * phi, n in [0, 1]
;; vec_A starting point
;; vec_C = vec_A - R * [ sin(beta - pi/2) , cos(beta - pi/2) ] ;; circle center
;; vec_r = vec_A + R * [ sin(phi' + beta - pi/2), cos(phi' + beta - pi/2) ] +- (direction) R * [sin(beta-pi/2), cos(beta-pi/2)] ;; point along circular path
;;
;;
(define (build-road)

  (set road-vertices (make-array 3000 "f4"))
  (set terrain-vertices (make-array 3000 "f4"))

  (let section-x 0.0)
  (let section-y 0.0)
  (let section-z 0.0)
  (let section-angle 0.0) ;; defined angle between +z axis, growing towards x: x = sin(phi), z = cos(phi)
  (let section-l 0.0)

  (let road-width 40.0)
  (let road-left-edge 30.0)
  (let road-right-edge 60.0)
  (let line-offset 34.0)
  (let line-thickness 2.0)

  (let num-sections 8)

  (let last-direction-sign -1.0)

  (for (i_sections num-sections)
       ;; generate random section
       (let section-length (clamp (+ 300 (* 300.0 (random-gauss))) 100.0 4000.0))
       (let straight (if (== i_sections 0) 0 (random)))

       (let direction-sign (if (< (random) 0.9) (* -1.0 last-direction-sign) last-direction-sign))

       (let direction (if (< straight 0.1) 0 (* direction-sign degrees-to-radians 14.0 (abs (random-gauss)))))
       (let phi (abs (* 2.0 direction)))
       (let radius (if (!= direction 0.0) (/ section-length phi) 0.0))
       (let section-l-direct (if (== direction 0.0) section-length (* 2.0 radius (sin (abs direction)))))


       (let num-segments 10)

       (let road-vertices-length 0)
       (let terrain-vertices-length 0)

       (set last-direction-sign direction-sign)
       (print "Section " i_sections " x " section-x " y " section-y " z " section-z " angle " (* radians-to-degrees section-angle) "\nlength " section-length " radius " radius " direction " (* radians-to-degrees direction) " l direct " section-l-direct "\n")

       (for (i (- num-segments 1))

            (do
              (let relative-pos (/ i (- num-segments 1))) ; 0..1 inside this section
              (let relative-pos2 (/ (+ i 1) (- num-segments 1))) ; next step

              (let current-l (+ section-l (* relative-pos section-length)))
              (let current-l2 (+ section-l (* relative-pos2 section-length)))

              (let angle0 (+ section-angle (* -0.5 pi)))
              (let angle1 (+ (* relative-pos 2.0 direction) section-angle (* -0.5 pi)))
              (let angle12 (+ (* relative-pos2 2.0 direction) section-angle (* -0.5 pi)))

              (let current-x (+ section-x (if (== direction 0.0) (* relative-pos section-length (sin section-angle)) (* direction-sign radius (- (sin angle1) (sin angle0))))))
              (let current-z (+ section-z (if (== direction 0.0) (* relative-pos section-length (cos section-angle)) (* direction-sign radius (- (cos angle1) (cos angle0))))))

              (let current-x2 (+ section-x (if (== direction 0.0) (* relative-pos2 section-length (sin section-angle)) (* direction-sign radius (- (sin angle12) (sin angle0)) ))))
              (let current-z2 (+ section-z (if (== direction 0.0) (* relative-pos2 section-length (cos section-angle)) (* direction-sign radius (- (cos angle12) (cos angle0)) ))))

              (let current-angle (+ section-angle (* relative-pos 2.0 direction)))
              (let current-angle2 (+ section-angle (* relative-pos2 2.0 direction)))

              (let dir-x (sin current-angle))
              (let dir-z (cos current-angle))
              (let dir-x2 (sin current-angle2))
              (let dir-z2 (cos current-angle2))

              (let perpendicular-x dir-z)
              (let perpendicular-z (- dir-x))

              (let perpendicular-x2 dir-z2)
              (let perpendicular-z2 (- dir-x2))


              (print "angle " (* radians-to-degrees current-angle) " dir x " dir-x " dir z " dir-z " perpendicular " perpendicular-x " " perpendicular-z "\n")

              ;; road triangles (set x, z) - add 2 triangles for current segment

              (do
                (let vertex-stride 8)
                (let left-offset road-width)
                (let right-offset (- road-width))
                (let x0 (+ (* perpendicular-x left-offset) current-x))
                (let z0 (+ (* perpendicular-z left-offset) current-z))
                (let x1 (+ (* perpendicular-x right-offset) current-x))
                (let z1 (+ (* perpendicular-z right-offset) current-z))

                (let x2 (+ (* perpendicular-x2 left-offset) current-x2))
                (let z2 (+ (* perpendicular-z2 left-offset) current-z2))
                (let x3 (+ (* perpendicular-x2 right-offset) current-x2))
                (let z3 (+ (* perpendicular-z2 right-offset) current-z2))

                (set road-vertices[road-vertices-length] x0)
                (set road-vertices[(+ road-vertices-length 1)] 0.0)
                (set road-vertices[(+ road-vertices-length 2)] z0)
                (set road-vertices[(+ road-vertices-length 6)] left-offset)
                (set road-vertices[(+ road-vertices-length 7)] current-l)
                (set road-vertices-length (+ road-vertices-length vertex-stride))

                (set road-vertices[road-vertices-length] x1)
                (set road-vertices[(+ road-vertices-length 1)] 0.0)
                (set road-vertices[(+ road-vertices-length 2)] z1)
                (set road-vertices[(+ road-vertices-length 6)] right-offset)
                (set road-vertices[(+ road-vertices-length 7)] current-l)
                (set road-vertices-length (+ road-vertices-length vertex-stride))

                (set road-vertices[road-vertices-length] x2)
                (set road-vertices[(+ road-vertices-length 1)] 0.0)
                (set road-vertices[(+ road-vertices-length 2)] z2)
                (set road-vertices[(+ road-vertices-length 6)] left-offset)
                (set road-vertices[(+ road-vertices-length 7)] current-l2)
                (set road-vertices-length (+ road-vertices-length vertex-stride))

                (set road-vertices[road-vertices-length] x2)
                (set road-vertices[(+ road-vertices-length 1)] 0.0)
                (set road-vertices[(+ road-vertices-length 2)] z2)
                (set road-vertices[(+ road-vertices-length 6)] left-offset)
                (set road-vertices[(+ road-vertices-length 7)] current-l2)
                (set road-vertices-length (+ road-vertices-length vertex-stride))

                (set road-vertices[road-vertices-length] x1)
                (set road-vertices[(+ road-vertices-length 1)] 0.0)
                (set road-vertices[(+ road-vertices-length 2)] z1)
                (set road-vertices[(+ road-vertices-length 6)] right-offset)
                (set road-vertices[(+ road-vertices-length 7)] current-l)
                (set road-vertices-length (+ road-vertices-length vertex-stride))

                (set road-vertices[road-vertices-length] x3)
                (set road-vertices[(+ road-vertices-length 1)] 0.0)
                (set road-vertices[(+ road-vertices-length 2)] z3)
                (set road-vertices[(+ road-vertices-length 6)] right-offset)
                (set road-vertices[(+ road-vertices-length 7)] current-l2)
                (set road-vertices-length (+ road-vertices-length vertex-stride))

                )

              ;; terrain
              (do
                (let left-height -100.0)
                (let right-cliff-offset 100.0)
                (let right-height 400.0)
                (let line-y-offset -1.0 )

                (let x0 (+ (* perpendicular-x (+ road-width road-left-edge)) current-x))
                (let z0 (+ (* perpendicular-z (+ road-width road-left-edge)) current-z))
                (let x1 (+ (* perpendicular-x (- 0.0 road-width road-right-edge)) current-x))
                (let z1 (+ (* perpendicular-z (- 0.0 road-width road-right-edge)) current-z))

                (let x2 (+ (* perpendicular-x2 (+ road-width road-left-edge)) current-x2))
                (let z2 (+ (* perpendicular-z2 (+ road-width road-left-edge)) current-z2))
                (let x3 (+ (* perpendicular-x2 (- 0.0 road-width road-right-edge)) current-x2))
                (let z3 (+ (* perpendicular-z2 (- 0.0 road-width road-right-edge)) current-z2))

                (let x6 (+ (* perpendicular-x (- 0.0 road-width road-right-edge right-cliff-offset)) current-x))
                (let z6 (+ (* perpendicular-z (- 0.0 road-width road-right-edge right-cliff-offset)) current-z))

                (let x7 (+ (* perpendicular-x2 (- 0.0 road-width road-right-edge right-cliff-offset)) current-x2))
                (let z7 (+ (* perpendicular-z2 (- 0.0 road-width road-right-edge right-cliff-offset)) current-z2))

                ;; 2 triangles, left cliff
                (set terrain-vertices[terrain-vertices-length] x0)
                (set terrain-vertices[(+ terrain-vertices-length 1)] (+ line-y-offset left-height))
                (set terrain-vertices[(+ terrain-vertices-length 2)] z0)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x0)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z0)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x2)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z2)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x0)
                (set terrain-vertices[(+ terrain-vertices-length 1)] (+ line-y-offset left-height))
                (set terrain-vertices[(+ terrain-vertices-length 2)] z0)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x2)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z2)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x2)
                (set terrain-vertices[(+ terrain-vertices-length 1)] (+ line-y-offset left-height))
                (set terrain-vertices[(+ terrain-vertices-length 2)] z2)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                ;; right cliff
                (set terrain-vertices[terrain-vertices-length] x1)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z1)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x6)
                (set terrain-vertices[(+ terrain-vertices-length 1)] (+ line-y-offset right-height))
                (set terrain-vertices[(+ terrain-vertices-length 2)] z6)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x7)
                (set terrain-vertices[(+ terrain-vertices-length 1)] (+ line-y-offset right-height))
                (set terrain-vertices[(+ terrain-vertices-length 2)] z7)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x1)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z1)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x7)
                (set terrain-vertices[(+ terrain-vertices-length 1)] (+ line-y-offset right-height))
                (set terrain-vertices[(+ terrain-vertices-length 2)] z7)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x3)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z3)
                (set terrain-vertices-length (+ terrain-vertices-length 6))


                ;; make 2 triangles under the road
                (set terrain-vertices[terrain-vertices-length] x0)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z0)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x1)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z1)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x2)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z2)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x2)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z2)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x1)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z1)
                (set terrain-vertices-length (+ terrain-vertices-length 6))

                (set terrain-vertices[terrain-vertices-length] x3)
                (set terrain-vertices[(+ terrain-vertices-length 1)] line-y-offset)
                (set terrain-vertices[(+ terrain-vertices-length 2)] z3)
                (set terrain-vertices-length (+ terrain-vertices-length 6))
                )


              )
            )

       (set section-x (+ section-x (* (sin (+ section-angle direction)) section-l-direct)))
       (set section-z (+ section-z (* (cos (+ section-angle direction)) section-l-direct)))
       (set section-angle (+ section-angle (* 2.0 direction)))
       (set section-l (+ section-l section-length))

       ; store as a vertex buffer

       ;; ROAD
       (do
         (let vertex-stride 8)
         (let tmp (make-array 1 "u4"))

         (glGenBuffers 1 tmp)
         (calculate-normals road-vertices road-vertices-length vertex-stride)
         (glBindBuffer GL_ARRAY_BUFFER tmp[0])
         (glBufferData GL_ARRAY_BUFFER (* road-vertices-length 4) road-vertices GL_STATIC_DRAW)

         (glGenVertexArrays 1 tmp)
         ;(print-array road-vertices road-vertices-length)
         ;(print "\n")
         (set road-vertex-arrays[road-vertex-arrays-count] tmp[0])
         (set road-vertex-arrays-vertex-count[road-vertex-arrays-count] (int/ road-vertices-length vertex-stride))
         ;(print "vertex count road: " road-vertex-arrays-vertex-count[road-vertex-arrays-count] "\n")
         (glBindVertexArray tmp[0])
         (glEnableVertexAttribArray 0)
         (glVertexAttribPointer 0 3 GL_FLOAT GL_FALSE (* vertex-stride 4) 0)
         (glEnableVertexAttribArray 1) ; normals
         (glVertexAttribPointer 1 3 GL_FLOAT GL_FALSE (* vertex-stride 4) (* 3 4))
         ;(glEnableVertexAttribArray 2) ; color
         ;(glVertexAttribPointer 2 3 GL_FLOAT GL_FALSE (* vertex-stride 4) (* 6 4))
         (glEnableVertexAttribArray 3) ; road position
         (glVertexAttribPointer 3 2 GL_FLOAT GL_FALSE (* vertex-stride 4) (* 6 4))
         (glBindVertexArray 0)
         (glBindBuffer GL_ARRAY_BUFFER 0)
         )

       (do
         (let vertex-stride 6)
         (let tmp (make-array 1 "u4"))

         (glGenBuffers 1 tmp)
         (glBindBuffer GL_ARRAY_BUFFER tmp[0])
         (calculate-normals terrain-vertices terrain-vertices-length vertex-stride)
         ;(print-array terrain-vertices terrain-vertices-length)
         (print "\n")
         (glBufferData GL_ARRAY_BUFFER (* terrain-vertices-length 4) terrain-vertices GL_STATIC_DRAW)

         (glGenVertexArrays 1 tmp)
         (set terrain-vertex-arrays[road-vertex-arrays-count] tmp[0])
         (set terrain-vertex-arrays-vertex-count[road-vertex-arrays-count] (int/ terrain-vertices-length vertex-stride))
         (glBindVertexArray tmp[0])
         (glEnableVertexAttribArray 0)
         (glVertexAttribPointer 0 3 GL_FLOAT GL_FALSE (* vertex-stride 4) 0)
         (glEnableVertexAttribArray 1) ; normals
         (glVertexAttribPointer 1 3 GL_FLOAT GL_FALSE (* vertex-stride 4) (* 3 4))
         ;(glEnableVertexAttribArray 2) ; color
         ;(glVertexAttribPointer 2 3 GL_FLOAT GL_FALSE (* vertex-stride 4) (* 6 4))
         (glBindVertexArray 0)
         (glBindBuffer GL_ARRAY_BUFFER 0)
         )

       (set road-vertex-arrays-count (+ road-vertex-arrays-count 1))

       )
  )

(define fbo)
(define fb-texture)
(define fb-depth-texture)

(define (render)
  (let light-x (* -1.0 (sin sun-pos[0]) (cos sun-pos[1])))
  (let light-y (sin sun-pos[1]))
  (let light-z (* -1.0 (cos sun-pos[0]) (cos sun-pos[1])))

  (set level (+ level direction))
  (if (== level 100.0) (set direction -1.0))
  (if (== level 0.0) (set direction 1.0))

  (if fbo
  (glBindFramebuffer GL_FRAMEBUFFER fbo) ;; render to framebuffer
    )

  (glViewport 0 0 render-width render-height)

  ; projection matrix
  ; transforms points from camera coordinate system (looking down negative z axis)
  ; to screen coordinates (-1..1, -1..1, -1..1)
  ;(make-ortho-projection-matrix projection-matrix -1.0 10.0 -10.0 10.0 0.2 20.0)
  (make-projection-matrix projection-matrix fovy (/ render-width render-height) 1.0 20000.0)

  ; view matrix
  ; 1. translate with -pos_camera (so world points are relative to the camera pos)
  ; 2. rotation 1: around vertical axis
  ; 3. rotation 2: around horizontal axis (x) along left-right direction
  ; 4. rotation 3: around axis along camera direction
  (make-translation-matrix temp-matrix (- camera-pos[0]) (- camera-pos[1]) (- camera-pos[2]))

  (make-rotation-matrix temp-matrix3 (- camera-angles[0]) 0.0 1.0 0.0)
  (make-rotation-matrix temp-matrix2 (- camera-angles[1]) 1.0 0.0 0.0)
  (mat4-multiply temp-matrix2 temp-matrix2 temp-matrix3)
  (make-rotation-matrix temp-matrix3 (- camera-angles[2]) 0.0 0.0 -1.0)
  (mat4-multiply temp-matrix2 temp-matrix3 temp-matrix2)
  (mat4-multiply view-matrix temp-matrix2 temp-matrix)

  (make-rotation-matrix temp-matrix3 (- camera-angles[0]) 0.0 1.0 0.0)
  (make-rotation-matrix temp-matrix2 (- camera-angles[1]) 1.0 0.0 0.0)
  (mat4-multiply temp-matrix2 temp-matrix2 temp-matrix3)
  (make-rotation-matrix temp-matrix3 (- camera-angles[2]) 0.0 0.0 -1.0)
  (mat4-multiply view-rotation-matrix temp-matrix3 temp-matrix2)

  (glClearColor 0.1 0.1 0.1 1.0)

  (glEnable GL_DEPTH_TEST)

  (glClear (+ GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT))

  ;;;
  ;;; TERRAIN
  ;;;
  (do ;comment
    (if shader-normal
      (do
        (glUseProgram shader-normal)

        ; model matrix
        ; input: model space points around model's center
        ; 1. scale model
        ; 2. do model rotation (around models center)
        ; 3. translate model with +object_pos, so center is now in worl at object_pos
        ;(make-rotation-matrix temp-matrix (/ level 40.0) 0.0 1.0 0.0)
        ;(make-rotation-matrix temp-matrix 0.0 0.0 1.0 0.0)
        (make-scaling-matrix temp-matrix 10.0 10.0 10.0)
        (make-translation-matrix temp-matrix2 0.0 0.0 0.0) ; position
        (mat4-multiply model-matrix temp-matrix2 temp-matrix)
        (glVertexAttrib3f 1 0.0 1.0 0.0)
        (glVertexAttrib3f 2 0.0 1.0 1.0)

        (glUniformMatrix4fv (glGetUniformLocation shader-normal "projection_matrix") 1 GL_TRUE projection-matrix)
        (glUniformMatrix4fv (glGetUniformLocation shader-normal "view_matrix") 1 GL_TRUE view-matrix)
        (glUniformMatrix4fv (glGetUniformLocation shader-normal "model_matrix") 1 GL_TRUE model-matrix)

        (glUniform3f (glGetUniformLocation shader-normal "camera_position") camera-pos[0] camera-pos[1] camera-pos[2])
        (glUniform2f (glGetUniformLocation shader-normal "sun_position") sun-pos[0] sun-pos[1])
        (glUniform3f (glGetUniformLocation shader-normal "sun_direction") light-x light-y light-z)

        (glBindVertexArray vertex-arr)
        (glDrawArrays GL_TRIANGLES 0 3)
        (glBindVertexArray 0)

        (make-scaling-matrix model-matrix 1.0 1.0 1.0)
        (glUniformMatrix4fv (glGetUniformLocation shader-normal "model_matrix") 1 GL_TRUE model-matrix)
        (do ;comment
          (for (i_sections road-vertex-arrays-count)
               (glVertexAttrib3f 2 1.0 0.0 1.0)
               (glBindVertexArray terrain-vertex-arrays[i_sections])
               (glDrawArrays GL_TRIANGLES 0 terrain-vertex-arrays-vertex-count[i_sections])
               (glBindVertexArray 0)
               ))
        ))
    )

  ;;;
  ;;; ROAD
  ;;;
  (do ;comment
    (if shader-road
      (do
        (glUseProgram shader-road)

        ; model matrix
        ; input: model space points around model's center
        ; 1. scale model
        ; 2. do model rotation (around models center)
        ; 3. translate model with +object_pos, so center is now in worl at object_pos
        (make-rotation-matrix temp-matrix 0.0 0.0 1.0 0.0)
        (make-translation-matrix temp-matrix2 0.0 0.0 0.0) ; position
        (mat4-multiply model-matrix temp-matrix2 temp-matrix)

        (glUniformMatrix4fv (glGetUniformLocation shader-road "projection_matrix") 1 GL_TRUE projection-matrix)
        (glUniformMatrix4fv (glGetUniformLocation shader-road "view_matrix") 1 GL_TRUE view-matrix)
        (glUniformMatrix4fv (glGetUniformLocation shader-road "model_matrix") 1 GL_TRUE model-matrix)

        ;(glVertexAttrib3f 1 0.0 1.0 0.0)
        (glVertexAttrib3f 2 0.7 0.7 0.3)

        (for (i_sections road-vertex-arrays-count)

             (glVertexAttrib3f 2 (/ i_sections road-vertex-arrays-count) 0.2 0.3)
             (glBindVertexArray road-vertex-arrays[i_sections])
             ;(glDrawArrays GL_LINE_STRIP 0 road-vertex-arrays-vertex-count[i_sections])
             ;(print "draw arrays " road-vertex-arrays-vertex-count[i_sections] "\n")
             (glDrawArrays GL_TRIANGLES 0 (* 2 road-vertex-arrays-vertex-count[i_sections]))
             (glBindVertexArray 0)
             )

        ))
    )


  ;;;
  ;;; SKY
  ;;;
  (do ;;comment
    (if shader-sky
      (do
        (glUseProgram shader-sky)

        (glUniform2f (glGetUniformLocation shader-sky "screenSize") render-width render-height)
        (glUniform1f (glGetUniformLocation shader-sky "fovy") fovy)
        (glUniformMatrix4fv (glGetUniformLocation shader-sky "view_matrix") 1 GL_TRUE view-rotation-matrix)
        (glUniform2f (glGetUniformLocation shader-sky "sun_position") sun-pos[0] sun-pos[1])

        (glDepthFunc GL_LEQUAL)
        (glBindVertexArray vertex-arr-quad)
        (glDrawArrays GL_TRIANGLE_STRIP 0 4)
        (glBindVertexArray 0)
        (glDepthFunc GL_LESS)

        ))
    )

  (glBindFramebuffer GL_FRAMEBUFFER 0) ;; render to screen

  (glViewport 0 0 width height)
  (glClearColor 0.4 0.4 0.1 1.0)
  (glClear (+ GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT))
  (do ;comment
    (if shader-quad
      (do
        (glUseProgram shader-quad)

        ; model matrix
        ; input: model space points around model's center
        ; 1. scale model
        ; 2. do model rotation (around models center)
        ; 3. translate model with +object_pos, so center is now in worl at object_pos
        (make-rotation-matrix temp-matrix (/ level 40.0) 0.0 1.0 0.0)
        (make-translation-matrix temp-matrix2 0.0 0.0 3.0) ; position
        (mat4-multiply model-matrix temp-matrix2 temp-matrix)

        (glUniform2i (glGetUniformLocation shader-quad "screen") width height)

        (glUniformMatrix4fv (glGetUniformLocation shader-quad "projection_matrix") 1 GL_TRUE projection-matrix)
        (glUniformMatrix4fv (glGetUniformLocation shader-quad "view_matrix") 1 GL_TRUE view-matrix)
        (glUniformMatrix4fv (glGetUniformLocation shader-quad "model_matrix") 1 GL_TRUE model-matrix)

        (glUniform1i (glGetUniformLocation shader-quad "tex") 0)
        (glUniform1i (glGetUniformLocation shader-quad "texDepth") 1)

        (glActiveTexture GL_TEXTURE0)
        (glBindTexture GL_TEXTURE_2D fb-texture)
        (glActiveTexture GL_TEXTURE1)
        (glBindTexture GL_TEXTURE_2D fb-depth-texture)
        ;;(print "fb texture " fb-texture "\n")
        (glBindVertexArray vertex-arr-quad)
        (glDrawArrays GL_TRIANGLE_STRIP 0 4)
        (glBindVertexArray 0)
        (glActiveTexture GL_TEXTURE0)
        (glBindTexture GL_TEXTURE_2D 0)
        (glActiveTexture GL_TEXTURE1)
        (glBindTexture GL_TEXTURE_2D 0)

        ))
    )

  (glUseProgram 0)

  (SDL_GL_SwapWindow w))

(define delta-time 1.0)
(define last-time (get-time))

(define (reload-shaders)
  ;(if shader-normal (glDeleteProgram shader-normal))
  ;(set shader-normal (load-shader vertex-shader frag-shader))
  ;;(set shader-normal (load-shader (load-file-string "basic3.vert") (load-file-string "basic3.frag")))
  (set shader-normal (load-shader (load-file-string "shading.vert") (load-file-string "shading.frag")))

  ;(if shader-sky (glDeleteProgram shader-sky))
  (set shader-sky (load-shader (load-file-string "sky.vert") (load-file-string "sky.frag")))

  ;(if shader-quad (glDeleteProgram shader-quad))
  ;(set shader-quad (load-shader (load-file-string "quad.vert") (load-file-string "quad.frag")))
  (set shader-quad (load-shader (load-file-string "postprocess.vert") (load-file-string "postprocess.frag")))

  ;(if shader-road (glDeleteProgram shader-road))
  (set shader-road (load-shader (load-file-string "road.vert") (load-file-string "road.frag")))
  )

(define (move-dir angle-offset amount)
  (set camera-pos[0] (+ camera-pos[0] (* (sin (+ pi angle-offset camera-angles[0])) amount)))
  (set camera-pos[2] (+ camera-pos[2] (* (cos (+ pi angle-offset camera-angles[0])) amount))))

(define (build-geometry)
  (let tmp (make-array 1 "u4"))
  (let quad-points (make-array 12 "f4"
                               -1.0 -1.0 0.0
                               1.0  -1.0 0.0
                               -1.0  1.0 0.0
                               1.0   1.0 0.0
                               ))

  ; triangle
  (glGenBuffers 1 tmp)
  (glBindBuffer GL_ARRAY_BUFFER tmp[0])
  (glBufferData GL_ARRAY_BUFFER (* (len points-array) 4) points-array GL_STATIC_DRAW)
  (glGenVertexArrays 1 tmp)
  (set vertex-arr tmp[0])
  (glBindVertexArray tmp[0])
  (glEnableVertexAttribArray 0)
  (glVertexAttribPointer 0 3 GL_FLOAT GL_FALSE 0 0)
  (glBindVertexArray 0)
  (glBindBuffer GL_ARRAY_BUFFER 0)

  (build-road)
  //(build-sky)

  ; quad vertex array (for fullscreen shaders)
  (glGenBuffers 1 tmp)
  (glBindBuffer GL_ARRAY_BUFFER tmp[0])
  (glBufferData GL_ARRAY_BUFFER (* (len quad-points) 4) quad-points GL_STATIC_DRAW)

  (glGenVertexArrays 1 tmp)
  (set vertex-arr-quad tmp[0])
  (glBindVertexArray tmp[0])
  (glEnableVertexAttribArray 0)
  (glVertexAttribPointer 0 3 GL_FLOAT GL_FALSE 0 0)
  (glBindVertexArray 0)
  (glBindBuffer GL_ARRAY_BUFFER 0)

  )


(define (main)
  (let ev-storage (make-array 80 "u4"))

  (print "Opengl vendor " (string-from-c-pointer (glGetString GL_VENDOR)) "\n")
  (print "Opengl version " (string-from-c-pointer (glGetString GL_VERSION)) "\n")

  (reload-shaders)
  (build-geometry)

  (do 
  (let tmp (make-array 1 "u4"))
  (glGenFramebuffers 1 tmp)
  (set fbo tmp[0])
  (glBindFramebuffer GL_FRAMEBUFFER fbo)

  (glGenTextures 1 tmp)
  (set fb-texture tmp[0])
  (glActiveTexture GL_TEXTURE0)
  (glBindTexture GL_TEXTURE_2D fb-texture)

  (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_LINEAR)
  (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MAG_FILTER GL_NEAREST)
  (glTexImage2D GL_TEXTURE_2D 0 GL_RGB render-width render-height 0 GL_RGB GL_UNSIGNED_BYTE 0)

  (glFramebufferTexture2D GL_FRAMEBUFFER GL_COLOR_ATTACHMENT0 GL_TEXTURE_2D fb-texture 0)

  (glBindTexture GL_TEXTURE_2D 0)
  (glGenTextures 1 tmp)
  ;(glActiveTexture GL_TEXTURE1)
  (set fb-depth-texture tmp[0])
  (comment
  (glBindTexture GL_TEXTURE_2D fb-depth-texture)

  (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER GL_LINEAR)
  (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MAG_FILTER GL_NEAREST)

  ;(glTexImage2D GL_TEXTURE_2D 0 GL_DEPTH24_STENCIL8 render-width render-height 0 GL_DEPTH_STENCIL GL_UNSIGNED_INT_24_8 0)
  ;(glFramebufferTexture2D GL_FRAMEBUFFER GL_DEPTH_STENCIL_ATTACHMENT GL_TEXTURE_2D fb-depth-texture 0)

  (glTexImage2D GL_TEXTURE_2D 0 GL_DEPTH_COMPONENT render-width render-height 0 GL_DEPTH_COMPONENT GL_UNSIGNED_BYTE 0)
  (glFramebufferTexture2D GL_FRAMEBUFFER GL_DEPTH_ATTACHMENT GL_TEXTURE_2D fb-depth-texture 0)

  (glBindTexture GL_TEXTURE_2D 0)
  )

  (glGenRenderbuffers 1 tmp)
  (glBindRenderbuffer GL_RENDERBUFFER tmp[0])
  (glRenderbufferStorage GL_RENDERBUFFER GL_DEPTH24_STENCIL8 render-width render-height)
  (glFramebufferRenderbuffer GL_FRAMEBUFFER GL_DEPTH_STENCIL_ATTACHMENT GL_RENDERBUFFER tmp[0])

  (glBindFramebuffer GL_FRAMEBUFFER 0)
  )

  (with-loop

    (do (let t1 (get-time))
      (set delta-time (- t1 last-time))
      ;(print "t1 " t1 " last " last-time " delta " (- t1 last-time) " d " delta-time "\n")
      (set last-time t1))

    (SDL_PollEvent ev-storage)

    (if (== ev-storage[0] SDL_EVENT_QUIT)
      (quit 0))

    (if (== ev-storage[0] SDL_EVENT_KEY_DOWN)
      (do 
        ;(print-array ev-storage)
        ;(print "Key down \n")
        ;(print "Scancode " ev-storage[10] "\n")

        (if (== ev-storage[10] SDL_SCANCODE_Q) (quit 0))
        (if (== ev-storage[10] SDL_SCANCODE_ESCAPE) (quit 0))
        (if (== ev-storage[10] SDL_SCANCODE_R) (reload-shaders))

        (if (== ev-storage[10] SDL_SCANCODE_UP) (set keys[0] 1))
        (if (== ev-storage[10] SDL_SCANCODE_DOWN) (set keys[1] 1))
        (if (== ev-storage[10] SDL_SCANCODE_LEFT) (set keys[2] 1))
        (if (== ev-storage[10] SDL_SCANCODE_RIGHT) (set keys[3] 1))

        (if (== ev-storage[10] SDL_SCANCODE_W) (set keys[4] 1))
        (if (== ev-storage[10] SDL_SCANCODE_S) (set keys[5] 1))
        (if (== ev-storage[10] SDL_SCANCODE_A) (set keys[6] 1))
        (if (== ev-storage[10] SDL_SCANCODE_D) (set keys[7] 1))

        (if (== ev-storage[10] SDL_SCANCODE_F) (set keys[8] 1))
        (if (== ev-storage[10] SDL_SCANCODE_V) (set keys[9] 1))
        (if (== ev-storage[10] SDL_SCANCODE_G) (set keys[10] 1))
        (if (== ev-storage[10] SDL_SCANCODE_B) (set keys[11] 1))

        (if (== ev-storage[10] SDL_SCANCODE_E) (set keys[12] 1))
        (if (== ev-storage[10] SDL_SCANCODE_C) (set keys[13] 1))

        (if (== ev-storage[10] SDL_SCANCODE_N) (set keys[14] 1))
        (if (== ev-storage[10] SDL_SCANCODE_M) (set keys[15] 1))
        ))

    (if (== ev-storage[0] SDL_EVENT_KEY_UP)
      (do 
        ;(print-array ev-storage)
        ;(print "Key up\n")
        ;(print "Scancode " ev-storage[5] "\n")

        (if (== ev-storage[10] SDL_SCANCODE_UP) (set keys[0] 0))
        (if (== ev-storage[10] SDL_SCANCODE_DOWN) (set keys[1] 0))
        (if (== ev-storage[10] SDL_SCANCODE_LEFT) (set keys[2] 0))
        (if (== ev-storage[10] SDL_SCANCODE_RIGHT) (set keys[3] 0))

        (if (== ev-storage[10] SDL_SCANCODE_W) (set keys[4] 0))
        (if (== ev-storage[10] SDL_SCANCODE_S) (set keys[5] 0))
        (if (== ev-storage[10] SDL_SCANCODE_A) (set keys[6] 0))
        (if (== ev-storage[10] SDL_SCANCODE_D) (set keys[7] 0))

        (if (== ev-storage[10] SDL_SCANCODE_F) (set keys[8] 0))
        (if (== ev-storage[10] SDL_SCANCODE_V) (set keys[9] 0))
        (if (== ev-storage[10] SDL_SCANCODE_G) (set keys[10] 0))
        (if (== ev-storage[10] SDL_SCANCODE_B) (set keys[11] 0))

        (if (== ev-storage[10] SDL_SCANCODE_E) (set keys[12] 0))
        (if (== ev-storage[10] SDL_SCANCODE_C) (set keys[13] 0))

        (if (== ev-storage[10] SDL_SCANCODE_N) (set keys[14] 0))
        (if (== ev-storage[10] SDL_SCANCODE_M) (set keys[15] 0))
        ))

    (if (== keys[0] 1) (move-dir 0.0 (* delta-time 300.0)))
    (if (== keys[1] 1) (move-dir pi (* delta-time 300.0)))
    (if (== keys[4] 1) (move-dir 0.0 (* delta-time 300.0)))
    (if (== keys[5] 1) (move-dir pi (* delta-time 300.0)))
    (if (== keys[6] 1) (move-dir (* 0.5 pi) (* delta-time 300.0)))
    (if (== keys[7] 1) (move-dir (* 1.5 pi) (* delta-time 300.0)))

    (if (== keys[12] 1) (set camera-pos[1] (+ camera-pos[1] (* delta-time 300.0))))
    (if (== keys[13] 1) (set camera-pos[1] (- camera-pos[1] (* delta-time 300.0))))

    (if (== keys[2] 1) (set camera-angles[0] (+ camera-angles[0] (* delta-time 3.0))))
    (if (== keys[3] 1) (set camera-angles[0] (- camera-angles[0] (* delta-time 3.0))))

    (if (== keys[8] 1) (set camera-angles[1] (+ camera-angles[1] (* delta-time 2.0))))
    (if (== keys[9] 1) (set camera-angles[1] (- camera-angles[1] (* delta-time 2.0))))

    (if (== keys[10] 1) (set camera-angles[2] (+ camera-angles[2] (* delta-time 2.0))))
    (if (== keys[11] 1) (set camera-angles[2] (- camera-angles[2] (* delta-time 2.0))))

    (if (== keys[14] 1) (set sun-pos[0] (+ sun-pos[0] (* delta-time 2.0))))
    (if (== keys[15] 1) (set sun-pos[0] (- sun-pos[0] (* delta-time 2.0))))

    (process-stdin)
    (render)

    (next-loop))


  //(SDL_GL_DeleteContext gl_context)
  (SDL_DestroyWindow w)
  (SDL_Quit))

(main)

