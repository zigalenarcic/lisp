
(load-dynamic-library "./test/libtest")

(define-c test_float ulong double float)
(define-c test_float2 ulong double double ulong double)

(define-c func1 ulong float float float float float float float float float float float)
(define-c func2 ulong ulong ulong ulong ulong ulong ulong ulong ulong ulong)
(define-c func3 ulong ulong float float float float float float float float float ulong float ulong ulong ulong ulong ulong float)

; call without prototype (up to 4 integer/ptr arguments)
(if (!= (test 10 1) 11)
  (do (print "Test failure!\n") (quit 1)))

(if (!= (test2 10 20 30 40)  100)
  (do (print "Test failure!\n") (quit 1)))

; call with prototype (floating point arguments)
(if (!= (test_float 33.2 23.23) 56)
  (do (print "Test failure!\n") (quit 1)))

(if (!= (test_float2 33.2 23.23 10 11.1) 77)
  (do (print "Test failure!\n") (quit 1)))

(do
  (let a (make-array 10 "i4"))
  (let b (make-array 10 "u8"))
  (let c "Test string!")
  (let d (make-array 10 "f4"))
  (set a[0] -1024)
  (set b[0] 10000000000)
  (set d[0] 1.123123)
(if (!= (test_ptr a b c d) 9999999061)
  (do (print "Test failure!\n") (quit 1))))


;(func1 1.1 2.2 3.3 4.4 4.9 8.1 9.0 10.2 11.8 12.2 13.3)
;(func2 1 2 3 4 5 6 7 8 9)
;(func3 112 2.2 3.3 4.4 4.9 8.1 9.1 9.2 9.8 10.2 123 12.3 1001 1002 1003 1004 1005 1007.3)

(do
  (let b 100)
  (let c 200)
  (let d 300)
  (let e 400)
  (let result (func3 e 2.2 3.3 4.4 4.9 8.1 9.1 9.2 9.8 10.2 123 12.3 1001 1002 1003 b e 1007.3))
  (if (!= result 5109)
    (do (print "Test failure!\n") (quit 1))))

(quit 0)
