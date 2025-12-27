ifneq (,$(shell which tcc))
CC=tcc
endif

EXECUTABLE_NAME=lisp

$(EXECUTABLE_NAME): vm_execute.asm main.c basicslib.h
	nasm -f elf64 vm_execute.asm
	$(CC) -g -o $@ main.c vm_execute.o -lm

TESTS = \
		test_basic.lisp \
		test_dynamic_library.lisp

.PHONY: test
test:
	$(CC) -shared -o test/libtest.so test/libtest.c
	for t in $(TESTS); do \
		./$(EXECUTABLE_NAME) test/$$t; if [ $$? -ne 0 ]; then echo "Test '"$$t"' FAILED!"; exit 1; fi \
		done
	echo "TESTS OK!"

.PHONY: clean
clean:
	rm -f vm_execute.o
	rm -f $(EXECUTABLE_NAME)

