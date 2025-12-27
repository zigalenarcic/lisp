# lisp

A performance oriented lisp language intepreter using a register-based bytecode VM written in ASM.

The goal is to achieve performance within the same order of magnitude compared to C code compiled without optimizations (realistically maybe 2x-3x slower in general).

## Building and running

Building requires NASM assembler, make and a C compiler.

```
make
```

To run the REPL:
```
./rex
```

To run code in a file:
```
./rex [filename]
```

## Running an example

Run an example (requires OpenGL and SDL3):
```
./rex example/opengl_triangle.lisp
```

An example benchmark program (sum of numbers up to 1e8):
```
(let (a 0) (for (i 100000000) (++ a i)) a)
```

