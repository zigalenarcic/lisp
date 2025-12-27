; Basic tests

(if (!= (+ 1 1) 2) (do (print "Test failed: arithmetic\n") (quit 1)))
(if (!= (+ 100 1) 101) (do (print "Test failed: arithmetic\n") (quit 1)))
(if (!= (* 100 1) 100) (do (print "Test failed: arithmetic\n") (quit 1)))
(if (!= (* 100 2) 200) (do (print "Test failed: arithmetic\n") (quit 1)))

(define var0 100)

(if (!= var0 100) (do (print "Test failed: var0 != 100\n") (quit 1)))

(define (a x) (+ x 1))

(if (!= (a 100) 101) (do (print "Test failed: function call a\n") (quit 1)))

(print "Test_basic succeded!\n")
(quit 0)
