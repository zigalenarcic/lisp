;
; ASM implementation of the bytecode VM
;
; Author: Ziga Lenarcic
;

; %define DEBUG_DECREF
; %define TRACE_CALL

; Microsoft x64 Win32 calling convention
; --------------------------------------
; Integer arguments: rcx, rdx, r8, r9
; Floating point arguments: xmm0 ... xmm3
; Arguments are stored according to position (e.g. if the 1st function argument is an int and 2nd a float, float is stored into xmm1)
; Stack shadow space is always allocated (for 4 arguments - 32 bytes)
; If there are more than 4 arguments, arguments are put on stack after the shadow space
; Return value: rax / xmm0 for floating point
; Non-volatile registers (must be saved and restored):
; rbx, rbp, rdi, rsi, rsp, r12 .. r15, xmm6 .. xmm15
;
; System V AMD64 ABI calling convention
; -------------------------------------
; Integer arguments: rdi, rsi, rdx, rcx, r8, r9
; Floating pointe arguments: xmm0 .. xmm7
; Registers are filled 1 by 1 arugment (e.g. first int arg is in rdi, first float in xmm0, etc.)
; Arguments that don't fit into registers are put on stack (no shadow space)
; (e.g. 7th integer argument is first value on stack)
; Stack is 16 byte aligned before call instruction.
; Return value: rax (+ rdx optionally for 128 bit return) / xmm0 for floating point
; Non-volatile registers (must be saved and restored):
; rbx, rbp, rsp, r12 .. r15

%ifdef WIN32
%define WIN32_CALLING_CONVENTION
%define PRE_FUNCTION_CALL sub rsp, 0x20
%define POST_FUNCTION_CALL add rsp, 0x20
%else
%define PRE_FUNCTION_CALL
%define POST_FUNCTION_CALL
%endif

%macro HELPER_1ARG 1
%1 0
%1 1
%1 2
%endmacro

%macro HELPER_1ARGFULL 1
%1 R
%1 0
%1 1
%1 2
%endmacro

%macro HELPER_2ARG 1
%1 0, 0
%1 0, 1
%1 0, 2
%1 1, 0
%1 1, 1
%1 1, 2
%1 2, 0
%1 2, 1
%1 2, 2
%endmacro

%macro HELPER_1ARG 2+
%1 0, %2
%1 1, %2
%1 2, %2
%endmacro

%macro HELPER_1ARGFULL 2+
%1 R, %2
%1 0, %2
%1 1, %2
%1 2, %2
%endmacro

%macro HELPER_2ARG 2+
%1 0, 0, %2
%1 0, 1, %2
%1 0, 2, %2
%1 1, 0, %2
%1 1, 1, %2
%1 1, 2, %2
%1 2, 0, %2
%1 2, 1, %2
%1 2, 2, %2
%endmacro

%macro HELPER_COND 1
%1 EQ, je
%1 NE, jne
%1 GT, jg
%1 LT, jl
%1 GE, jge
%1 LE, jle
%endmacro

%ifdef WIN32_CALLING_CONVENTION
%macro HELPER_ARG 1
%1 R, R
%1 0, R
%1 1, R
%1 2, R
%1 3, R
%1 R, 0
%1 0, 0
%1 1, 0
%1 2, 0
%1 3, 0
%1 R, 1
%1 0, 1
%1 1, 1
%1 2, 1
%1 3, 1
%1 R, 2
%1 0, 2
%1 1, 2
%1 2, 2
%1 3, 2
%1 R, I
%1 0, I
%1 1, I
%1 2, I
%1 3, I
%endmacro

%macro HELPER_ARG_FLOAT 1
%1 R, R
%1 0, R
%1 1, R
%1 2, R
%1 3, R
%1 R, 0
%1 0, 0
%1 1, 0
%1 2, 0
%1 3, 0
%1 R, 1
%1 0, 1
%1 1, 1
%1 2, 1
%1 3, 1
%1 R, 2
%1 0, 2
%1 1, 2
%1 2, 2
%1 3, 2
%1 R, I
%1 0, I
%1 1, I
%1 2, I
%1 3, I
%endmacro
%else
%macro HELPER_ARG 1
%1 R, R
%1 0, R
%1 1, R
%1 2, R
%1 3, R
%1 4, R
%1 5, R
%1 R, 0
%1 0, 0
%1 1, 0
%1 2, 0
%1 3, 0
%1 4, 0
%1 5, 0
%1 R, 1
%1 0, 1
%1 1, 1
%1 2, 1
%1 3, 1
%1 4, 1
%1 5, 1
%1 R, 2
%1 0, 2
%1 1, 2
%1 2, 2
%1 3, 2
%1 4, 2
%1 5, 2
%1 R, I
%1 0, I
%1 1, I
%1 2, I
%1 3, I
%1 4, I
%1 5, I
%endmacro

%macro HELPER_ARG_FLOAT 1
%1 R, R
%1 0, R
%1 1, R
%1 2, R
%1 3, R
%1 4, R
%1 5, R
%1 6, R
%1 7, R
%1 R, 0
%1 0, 0
%1 1, 0
%1 2, 0
%1 3, 0
%1 4, 0
%1 5, 0
%1 6, 0
%1 7, 0
%1 R, 1
%1 0, 1
%1 1, 1
%1 2, 1
%1 3, 1
%1 4, 1
%1 5, 1
%1 6, 1
%1 7, 1
%1 R, 2
%1 0, 2
%1 1, 2
%1 2, 2
%1 3, 2
%1 4, 2
%1 5, 2
%1 6, 2
%1 7, 2
%1 R, I
%1 0, I
%1 1, I
%1 2, I
%1 3, I
%1 4, I
%1 5, I
%1 6, I
%1 7, I
%endmacro
%endif

%macro I_OFFSET 1
dq %{1} - vm_execute
%endmacro

%macro INST_OFFSET1 1
I_OFFSET %{1}R
I_OFFSET %{1}0
I_OFFSET %{1}1
I_OFFSET %{1}2
%endmacro

%macro INST_OFFSET1 2
I_OFFSET %{1}R%2
I_OFFSET %{1}0%2
I_OFFSET %{1}1%2
I_OFFSET %{1}2%2
%endmacro

%macro INST_OFFSET2 1
I_OFFSET %{1}RR
I_OFFSET %{1}R0
I_OFFSET %{1}0R
I_OFFSET %{1}R1
I_OFFSET %{1}1R
I_OFFSET %{1}R2
I_OFFSET %{1}2R
I_OFFSET %{1}00
I_OFFSET %{1}01
I_OFFSET %{1}02
I_OFFSET %{1}10
I_OFFSET %{1}11
I_OFFSET %{1}12
I_OFFSET %{1}20
I_OFFSET %{1}21
I_OFFSET %{1}22
%endmacro

%macro INST_OFFSET_COND 1
I_OFFSET %{1}EQ
I_OFFSET %{1}NE
I_OFFSET %{1}GT
I_OFFSET %{1}LT
I_OFFSET %{1}GE
I_OFFSET %{1}LE
%endmacro

%ifdef WIN32_CALLING_CONVENTION
%macro INST_OFFSET_ARG 1
I_OFFSET %{1}RR
I_OFFSET %{1}0R
I_OFFSET %{1}1R
I_OFFSET %{1}2R
I_OFFSET %{1}3R
I_OFFSET %{1}R0
I_OFFSET %{1}00
I_OFFSET %{1}10
I_OFFSET %{1}20
I_OFFSET %{1}30
I_OFFSET %{1}R1
I_OFFSET %{1}01
I_OFFSET %{1}11
I_OFFSET %{1}21
I_OFFSET %{1}31
I_OFFSET %{1}R2
I_OFFSET %{1}02
I_OFFSET %{1}12
I_OFFSET %{1}22
I_OFFSET %{1}32
I_OFFSET %{1}RI
I_OFFSET %{1}0I
I_OFFSET %{1}1I
I_OFFSET %{1}2I
I_OFFSET %{1}3I
%endmacro

%macro INST_OFFSET_ARG_FLOAT 1
I_OFFSET %{1}RR
I_OFFSET %{1}0R
I_OFFSET %{1}1R
I_OFFSET %{1}2R
I_OFFSET %{1}3R
I_OFFSET %{1}R0
I_OFFSET %{1}00
I_OFFSET %{1}10
I_OFFSET %{1}20
I_OFFSET %{1}30
I_OFFSET %{1}R1
I_OFFSET %{1}01
I_OFFSET %{1}11
I_OFFSET %{1}21
I_OFFSET %{1}31
I_OFFSET %{1}R2
I_OFFSET %{1}02
I_OFFSET %{1}12
I_OFFSET %{1}22
I_OFFSET %{1}32
I_OFFSET %{1}RI
I_OFFSET %{1}0I
I_OFFSET %{1}1I
I_OFFSET %{1}2I
I_OFFSET %{1}3I
%endmacro
%else
%macro INST_OFFSET_ARG 1
I_OFFSET %{1}RR
I_OFFSET %{1}0R
I_OFFSET %{1}1R
I_OFFSET %{1}2R
I_OFFSET %{1}3R
I_OFFSET %{1}4R
I_OFFSET %{1}5R
I_OFFSET %{1}R0
I_OFFSET %{1}00
I_OFFSET %{1}10
I_OFFSET %{1}20
I_OFFSET %{1}30
I_OFFSET %{1}40
I_OFFSET %{1}50
I_OFFSET %{1}R1
I_OFFSET %{1}01
I_OFFSET %{1}11
I_OFFSET %{1}21
I_OFFSET %{1}31
I_OFFSET %{1}41
I_OFFSET %{1}51
I_OFFSET %{1}R2
I_OFFSET %{1}02
I_OFFSET %{1}12
I_OFFSET %{1}22
I_OFFSET %{1}32
I_OFFSET %{1}42
I_OFFSET %{1}52
I_OFFSET %{1}RI
I_OFFSET %{1}0I
I_OFFSET %{1}1I
I_OFFSET %{1}2I
I_OFFSET %{1}3I
I_OFFSET %{1}4I
I_OFFSET %{1}5I
%endmacro

%macro INST_OFFSET_ARG_FLOAT 1
I_OFFSET %{1}RR
I_OFFSET %{1}0R
I_OFFSET %{1}1R
I_OFFSET %{1}2R
I_OFFSET %{1}3R
I_OFFSET %{1}4R
I_OFFSET %{1}5R
I_OFFSET %{1}6R
I_OFFSET %{1}7R
I_OFFSET %{1}R0
I_OFFSET %{1}00
I_OFFSET %{1}10
I_OFFSET %{1}20
I_OFFSET %{1}30
I_OFFSET %{1}40
I_OFFSET %{1}50
I_OFFSET %{1}60
I_OFFSET %{1}70
I_OFFSET %{1}R1
I_OFFSET %{1}01
I_OFFSET %{1}11
I_OFFSET %{1}21
I_OFFSET %{1}31
I_OFFSET %{1}41
I_OFFSET %{1}51
I_OFFSET %{1}61
I_OFFSET %{1}71
I_OFFSET %{1}R2
I_OFFSET %{1}02
I_OFFSET %{1}12
I_OFFSET %{1}22
I_OFFSET %{1}32
I_OFFSET %{1}42
I_OFFSET %{1}52
I_OFFSET %{1}62
I_OFFSET %{1}72
I_OFFSET %{1}RI
I_OFFSET %{1}0I
I_OFFSET %{1}1I
I_OFFSET %{1}2I
I_OFFSET %{1}3I
I_OFFSET %{1}4I
I_OFFSET %{1}5I
I_OFFSET %{1}6I
I_OFFSET %{1}7I
%endmacro
%endif

section .ro_data

global instruction_offset
instruction_offset: 
I_OFFSET I_RESERVE_STACK
INST_OFFSET2 I_MOVE
INST_OFFSET1 I_MOVE, I
INST_OFFSET1 I_MOVE, GLOBAL
INST_OFFSET1 I_MOVEGLOBAL
I_OFFSET I_MOVEGLOBALFUNI
INST_OFFSET2 I_ADD
INST_OFFSET1 I_ADD, I
INST_OFFSET1 I_ADD, IF
INST_OFFSET2 I_SUB
INST_OFFSET2 I_MUL
INST_OFFSET1 I_MUL, I
INST_OFFSET1 I_MUL, IF
INST_OFFSET2 I_DIV
INST_OFFSET1 I_NEGATE
I_OFFSET I_JMP
INST_OFFSET2 I_CMP
INST_OFFSET1 I_CMP, I
INST_OFFSET2 I_INC_JMP_LT
INST_OFFSET_COND I_JMP_
INST_OFFSET1 I_RETC
INST_OFFSET1 I_RET
I_OFFSET I_CALL
I_OFFSET I_CALLINTN
INST_OFFSET1 I_CALLINT
I_OFFSET I_CALLEXTN
INST_OFFSET1 I_CALLEXT
INST_OFFSET1 I_MOVERETVAL
INST_OFFSET1 I_INCREF
INST_OFFSET1 I_DECREF
INST_OFFSET2 I_AINDEX
INST_OFFSET1 I_AINDEX, I
INST_OFFSET2 I_SAINDEX
INST_OFFSET1 I_SAVALUE
I_OFFSET I_READ_OBJ
I_OFFSET I_READ_I1
I_OFFSET I_READ_U1
I_OFFSET I_READ_I2
I_OFFSET I_READ_U2
I_OFFSET I_READ_I4
I_OFFSET I_READ_U4
I_OFFSET I_READ_I8
I_OFFSET I_READ_U8
I_OFFSET I_READ_F4
I_OFFSET I_READ_F8
I_OFFSET I_STORE_OBJ
I_OFFSET I_STORE_I1
I_OFFSET I_STORE_U1
I_OFFSET I_STORE_I2
I_OFFSET I_STORE_U2
I_OFFSET I_STORE_I4
I_OFFSET I_STORE_U4
I_OFFSET I_STORE_I8
I_OFFSET I_STORE_U8
I_OFFSET I_STORE_F4
I_OFFSET I_STORE_F8
INST_OFFSET_ARG I_ULONGARG
INST_OFFSET_ARG I_PTRARG
INST_OFFSET_ARG_FLOAT I_F8ARG
INST_OFFSET_ARG_FLOAT I_F4ARG
I_OFFSET I_CALLEXT2N
INST_OFFSET1 I_CALLEXT2
I_OFFSET I_CALLEXT2_PREPARE
I_OFFSET I_DEBUG_BREAK

global instruction_count
instruction_count: dq (instruction_count - instruction_offset) / 8

section .text

extern free_object
extern trace_function

%define TOP_BIT_64 0x8000000000000000
%define INTEGER_1 2 ; integer 1 immediate representation
%define NONE_VALUE 3 ; None immediate representation

%define SYMBOL_VALUE_OFFSET 16 ; offset of the value field in symbol_t
%define SYMBOL_FUNCTION_VALUE_OFFSET 24 ; offset of functio_value field in symbol_t
%define SYMBOL_FLAGS_OFFSET 32 ; offset of the flags field in symbol_t
%define SF_HAS_VALUE 1
%define SF_HAS_FUNCTION_VALUE 4
%define FUNCTION_PTR_OFFSET 16 ; offset of bytecode field in function_t
%define ARRAY_STORAGE_OFFSET 16 ; offset of storage field in array_t
%define ARRAY_READ_BYTECODE_OFFSET 40 ; offset of 'read_bytecode' field in array_t
%define ARRAY_STORE_BYTECODE_OFFSET 48 ; offset of 'store_bytecode' field in array_t
%define STACK_TOP_PADDING 8 ; offset to call arguments at call time
%define INTEGER_SHIFT 1 ; number of bits of shifting for integer numbers to get the numeric value

%define alignment align 1

%ifdef WIN32_CALLING_CONVENTION
%define ARG_REG_0 rcx
%define ARG_REG_1 rdx
%define ARG_REG_2 r8
%define ARG_REG_3 r9
%else
%define ARG_REG_0 rdi
%define ARG_REG_1 rsi
%define ARG_REG_2 rdx
%define ARG_REG_3 rcx
%define ARG_REG_4 r8
%define ARG_REG_5 r9
%endif

%define FLOAT_ARG_REG_0 xmm0
%define FLOAT_ARG_REG_1 xmm1
%define FLOAT_ARG_REG_2 xmm2
%define FLOAT_ARG_REG_3 xmm3
%define FLOAT_ARG_REG_4 xmm4
%define FLOAT_ARG_REG_5 xmm5
%define FLOAT_ARG_REG_6 xmm6
%define FLOAT_ARG_REG_7 xmm7
%define FLOAT_REG_TMP xmm8

%define T0 rdx ; temporary register 0
%define T1 rcx ; temporary register 1
%define T2 rax ; temporary register 2
%define T3 rsi ; temporary register 3
%define REG_0 r12 ; callee saved r12 - r15
%define REG_1 r13
%define REG_2 r14
%define STACK_REG r15
%define CODE_REG rbx ; callee saved
%define VM_EXECUTE_STACK_RESERVE 0x30
%define RBX_STACK_LOC [rbp - 0x08]
%define INTERP_STACK_LOC [rbp - 0x10]
%define T0_STACK_LOC [rbp - 0x18]
%define T1_STACK_LOC [rbp - 0x20]
%define T2_STACK_LOC [rbp - 0x28]
%define T3_STACK_LOC [rbp - 0x30]
%define T_RAX_STACK_LOC T2_STACK_LOC

; args: vm_execute(code_ptr, reg_space_ptr)
global vm_execute
alignment
vm_execute:
  push rbp
  ;; save registers which will be used
%ifdef WIN32_CALLING_CONVENTION
  push rdi
  push rsi
%endif
  push r12
  push r13
  push r14
  push r15
  mov rbp, rsp
  sub rsp, VM_EXECUTE_STACK_RESERVE ; stack must be 16 byte aligned on calls
  mov RBX_STACK_LOC, rbx ; must store it and restore it if it is used
  mov CODE_REG, ARG_REG_0 ; array of bytecode in rbx
  mov STACK_REG, ARG_REG_1 ; array of registers ('register file/stack')
  mov INTERP_STACK_LOC, ARG_REG_2

%define FLOAT_BITS 1 ; floats have 0b01 tag
%define BIT_MASK -4 ; and - to clear lower two bits
%define REG_ADDR(x) QWORD [STACK_REG + x * 8]

%macro NEXT_INSTRUCTION 0
  jmp [CODE_REG]
%endmacro

  NEXT_INSTRUCTION

alignment
I_RESERVE_STACK:
  mov T0, [CODE_REG + 8]
  add CODE_REG, 16
  sub STACK_REG, T0
  mov [STACK_REG], T0
  NEXT_INSTRUCTION

alignment
I_MOVERR:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  mov T1, REG_ADDR(T1)
  mov REG_ADDR(T0), T1
  NEXT_INSTRUCTION

%macro I_MOVER_MACRO 1
alignment
I_MOVER%1:
  mov T0, [CODE_REG + 8]
  add CODE_REG, 16
  mov REG_ADDR(T0), REG_%1
  NEXT_INSTRUCTION

alignment
I_MOVE%{1}R:
  mov T0, [CODE_REG + 8]
  add CODE_REG, 16
  mov REG_%1, REG_ADDR(T0)
  NEXT_INSTRUCTION
%endmacro

%macro I_MOVE__MACRO 2
alignment
I_MOVE%1%2:
  add CODE_REG, 8
  mov REG_%1, REG_%2
  NEXT_INSTRUCTION
%endmacro

HELPER_1ARG I_MOVER_MACRO

HELPER_2ARG I_MOVE__MACRO

%macro JUMP_NOT_REFERENCE_COUNTED 3
  test %1, 1 ; number has bit 0 = 0
  jz %3
  test %1, 2 ; float has bits 1-0 = 01
  jz %3
  cmp %1, 3
  je %3
%endmacro

%macro TESTINCREF 2
  JUMP_NOT_REFERENCE_COUNTED %1, %2, %%incref.1
  and %1, BIT_MASK ; get pointer
  mov %2, 1
  lock xadd QWORD [%1], %2 ; increment by one
%%incref.1:
%endmacro

%macro TESTDECREF 2
  JUMP_NOT_REFERENCE_COUNTED %1, %2, %%decref.1
  and %1, BIT_MASK ; get pointer
  mov %2, 1
  neg %2
  lock xadd QWORD [%1], %2 ; not operation width
%ifdef DEBUG_DECREF
  ;; DEBUG - check if refcount was already 0
  cmp %2, 0
  jne %%decref.2
  int3
  nop
%%decref.2:
%endif
  cmp %2, 1
  jnz %%decref.1
  ; count is 0, free object
  mov ARG_REG_0, INTERP_STACK_LOC ; arg0
  mov ARG_REG_1, %1 ; arg1 - object
  add ARG_REG_1, 3
  PRE_FUNCTION_CALL
  call free_object ; free the object
  POST_FUNCTION_CALL
%%decref.1:
%endmacro

alignment
I_MOVERI:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  mov REG_ADDR(T0), T1
  TESTINCREF T1, T0 ; incref the value
  NEXT_INSTRUCTION

%macro I_MOVE_IMACRO 1
alignment
I_MOVE%{1}I:
  mov REG_%1, [CODE_REG + 8]
  mov T0, REG_%1
  add CODE_REG, 16
  TESTINCREF T0, T1 ; incref the value
  NEXT_INSTRUCTION
%endmacro

HELPER_1ARG I_MOVE_IMACRO

alignment
I_MOVERGLOBAL:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  and T1, BIT_MASK
  mov T1, [T1 + SYMBOL_VALUE_OFFSET]
  mov REG_ADDR(T0), T1
  TESTINCREF T1, T0 ; incref the value
  NEXT_INSTRUCTION

%macro I_MOVE_GLOBALMACRO 1
alignment
I_MOVE%{1}GLOBAL:
  mov T0, [CODE_REG + 8]
  add CODE_REG, 16
  and T0, BIT_MASK
  mov REG_%1, [T0 + SYMBOL_VALUE_OFFSET]
  mov T0, REG_%1
  TESTINCREF T0, T1 ; incref the value
  NEXT_INSTRUCTION
%endmacro

HELPER_1ARG I_MOVE_GLOBALMACRO

alignment
I_MOVEGLOBALR:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  and T1, BIT_MASK
  mov T2, [T1 + SYMBOL_VALUE_OFFSET] ; store previous value
  mov T0, REG_ADDR(T0)
  mov [T1 + SYMBOL_VALUE_OFFSET], T0 ; store the value
  or [T1 + SYMBOL_FLAGS_OFFSET], SF_HAS_VALUE
  ; decref previous value
  TESTDECREF T2, T0
  NEXT_INSTRUCTION

%macro I_MOVEGLOBAL_MACRO 1
alignment
I_MOVEGLOBAL%{1}:
  mov T0, [CODE_REG + 8]
  add CODE_REG, 16
  and T0, BIT_MASK
  mov T2, [T0 + SYMBOL_VALUE_OFFSET] ; store previous value
  mov [T0 + SYMBOL_VALUE_OFFSET], REG_%1 ; store the value
  or [T0 + SYMBOL_FLAGS_OFFSET], SF_HAS_VALUE
  ; decref previous value
  TESTDECREF T2, T0
  NEXT_INSTRUCTION
%endmacro

HELPER_1ARG I_MOVEGLOBAL_MACRO

alignment
I_MOVEGLOBALFUNI:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  and T0, BIT_MASK
  mov T2, [T0 + SYMBOL_FUNCTION_VALUE_OFFSET] ; store previous value
  mov [T0 + SYMBOL_FUNCTION_VALUE_OFFSET], T1 ; store the value
  or [T0 + SYMBOL_FLAGS_OFFSET], SF_HAS_FUNCTION_VALUE
  ; decref previous value
  TESTDECREF T2, T0
  NEXT_INSTRUCTION

%macro JUMP_IS_FLOAT 3
  test %1, 1
  jz %%not_float
  test %1, 2
  jz %3
%%not_float:
%endmacro

; arguments: register with value, temp register, xmm register
%macro FLOAT_REG_TO_XMM 3
  mov %2, %1
  and %2, BIT_MASK
  movq %3, %2
%endmacro

%macro INT_REG_TO_XMM 2
  sar %1, INTEGER_SHIFT
  cvtsi2sd %2, %1
%endmacro

%macro INT_REG_TO_XMM 3
  mov %2, %1
  sar %2, INTEGER_SHIFT
  cvtsi2sd %3, %2
%endmacro

%macro I_OPRR_MACRO 3
alignment
I_%{1}RR:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  mov T2, REG_ADDR(T0)
  mov T1, REG_ADDR(T1)
  JUMP_IS_FLOAT T2, T3, I_%{1}RR_arg1float
  JUMP_IS_FLOAT T1, T3, I_%{1}RR_arg2float
%ifidn %{1},DIV ; div - always produce a floating point result
  INT_REG_TO_XMM T2, xmm0
  INT_REG_TO_XMM T1, xmm1
  %{3} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%else
%ifidn %{1},MUL
  sar T2, INTEGER_SHIFT
%endif
  %{2} T2, T1
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%endif
I_%{1}RR_arg1float:
  JUMP_IS_FLOAT T1, T3, I_%{1}RR_arg12float
  FLOAT_REG_TO_XMM T2, T3, xmm0
  INT_REG_TO_XMM T1, xmm1
  %{3} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
I_%{1}RR_arg2float:
  INT_REG_TO_XMM T2, xmm0
  FLOAT_REG_TO_XMM T1, T3, xmm1
  %{3} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
I_%{1}RR_arg12float:
  FLOAT_REG_TO_XMM T2, T3, xmm0
  FLOAT_REG_TO_XMM T1, T3, xmm1
  %{3} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%endmacro

%macro I_OPR_MACRO 4
alignment
I_%{2}R%{1}:
  mov T0, [CODE_REG + 8]
  mov T2, REG_ADDR(T0)
  add CODE_REG, 16
  test T2, 1
  jnz %%I_%{2}R__arg1_float
  test REG_%1, 1
  jnz %%I_%{2}R__arg2_float
%ifidn %{2},DIV ; div - always produce a floating point result
  INT_REG_TO_XMM T2, xmm0
  INT_REG_TO_XMM REG_%1, T3, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%else
%ifidn %{2},MUL
  sar T2, INTEGER_SHIFT
%endif
  %{3} T2, REG_%1
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%endif
%%I_%{2}R__arg1_float:
  test REG_%1, 1
  jnz %%I_%{2}R__arg12_float
  FLOAT_REG_TO_XMM T2, T3, xmm0
  INT_REG_TO_XMM REG_%1, T3, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%%I_%{2}R__arg2_float:
  INT_REG_TO_XMM T2, xmm0
  FLOAT_REG_TO_XMM REG_%1, T3, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%%I_%{2}R__arg12_float:
  FLOAT_REG_TO_XMM T2, T3, xmm0
  FLOAT_REG_TO_XMM REG_%1, T3, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION

alignment
I_%{2}%{1}R:
  mov T0, [CODE_REG + 8]
  mov T2, REG_ADDR(T0)
  add CODE_REG, 16
  test REG_%1, 1
  jnz %%I_%{2}_R_arg1_float
  test T2, 1
  jnz %%I_%{2}_R_arg2_float
%ifidn %{2},DIV ; div - always produce a floating point result
  INT_REG_TO_XMM REG_%1, T3, xmm0
  INT_REG_TO_XMM T2, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%{1}, T2
  NEXT_INSTRUCTION
%else
%ifidn %{2},MUL
  sar REG_%1, INTEGER_SHIFT
%endif
  %{3} REG_%{1}, T2
  NEXT_INSTRUCTION
%endif
%%I_%{2}_R_arg1_float:
  test T2, 1
  jnz %%I_%{2}_R_arg12_float
  FLOAT_REG_TO_XMM REG_%1, T3, xmm0
  INT_REG_TO_XMM T2, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%{1}, T2
  NEXT_INSTRUCTION
%%I_%{2}_R_arg2_float:
  INT_REG_TO_XMM REG_%1, T3, xmm0
  FLOAT_REG_TO_XMM T2, T3, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%{1}, T2
  NEXT_INSTRUCTION
%%I_%{2}_R_arg12_float:
  FLOAT_REG_TO_XMM REG_%1, T3, xmm0
  FLOAT_REG_TO_XMM T2, T3, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%{1}, T2
  NEXT_INSTRUCTION
%endmacro

%macro I_OP__MACRO 5
alignment
I_%{3}%{1}%{2}:
  add CODE_REG, 8
  test REG_%{1}, 1
  jnz %%I_%{3}___arg1_float
  test REG_%{2}, 1
  jnz %%I_%{3}___arg2_float
%ifidn %{3},DIV ; div - always produce a floating point result
  INT_REG_TO_XMM REG_%{1}, T3, xmm0
  INT_REG_TO_XMM REG_%{2}, T3, xmm1
  %{5} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%{1}, T2
  NEXT_INSTRUCTION
%else
%ifidn %{3},MUL
  sar REG_%1, INTEGER_SHIFT
%endif
  %{4} REG_%1, REG_%2
  NEXT_INSTRUCTION
%endif
%%I_%{3}___arg1_float:
  test REG_%2, 1
  jnz %%I_%{3}___arg12_float
  FLOAT_REG_TO_XMM REG_%1, T3, xmm0
  INT_REG_TO_XMM REG_%2, T3, xmm1
  %{5} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%1, T2
  NEXT_INSTRUCTION
%%I_%{3}___arg2_float:
  INT_REG_TO_XMM REG_%1, T3, xmm0
  FLOAT_REG_TO_XMM REG_%2, T3, xmm1
  %{5} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%1, T2
  NEXT_INSTRUCTION
%%I_%{3}___arg12_float:
  FLOAT_REG_TO_XMM REG_%1, T3, xmm0
  FLOAT_REG_TO_XMM REG_%2, T3, xmm1
  %{5} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%1, T2
  NEXT_INSTRUCTION
%endmacro

%macro I_OPRIMACRO 3
alignment
I_%{1}RI:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  mov T2, REG_ADDR(T0)
  test T2, 1
  jnz %%I_%{1}RI_arg1_float
%ifidn %{1},MUL
  sar T2, INTEGER_SHIFT
%endif
  %{2} T2, T1
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%%I_%{1}RI_arg1_float:
  FLOAT_REG_TO_XMM T2, T3, xmm0
  INT_REG_TO_XMM T1, xmm1
  %{3} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION

alignment
I_%{1}RIF:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  mov T2, REG_ADDR(T0)
  test T2, 1
  jnz %%I_%{1}RIF_arg1_float
  INT_REG_TO_XMM T2, xmm0 ; T2 int
  FLOAT_REG_TO_XMM T1, T3, xmm1 ; T1 float
  %{3} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%%I_%{1}RIF_arg1_float:
  FLOAT_REG_TO_XMM T2, T3, xmm0
  FLOAT_REG_TO_XMM T1, T3, xmm1
  %{3} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_ADDR(T0), T2
  NEXT_INSTRUCTION
%endmacro

%macro I_OP_IMACRO 4
alignment
I_%{2}%{1}I:
  mov T2, [CODE_REG + 8]
  add CODE_REG, 16
  test REG_%{1}, 1
  jnz %%I_%{2}_I_arg1_float
%ifidn %{2},MUL
  sar REG_%1, INTEGER_SHIFT
%endif
  %{3} REG_%1, T2
  NEXT_INSTRUCTION
%%I_%{2}_I_arg1_float:
  FLOAT_REG_TO_XMM REG_%1, T3, xmm0
  INT_REG_TO_XMM T2, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%1, T2
  NEXT_INSTRUCTION

alignment
I_%{2}%{1}IF:
  mov T2, [CODE_REG + 8]
  add CODE_REG, 16
  test REG_%{1}, 1
  jnz %%I_%{2}_IF_arg1_float
  INT_REG_TO_XMM REG_%1, T3, xmm0
  FLOAT_REG_TO_XMM T2, T3, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%1, T2
  NEXT_INSTRUCTION
%%I_%{2}_IF_arg1_float:
  FLOAT_REG_TO_XMM REG_%1, T3, xmm0
  FLOAT_REG_TO_XMM T2, T3, xmm1
  %{4} xmm0, xmm1
  movq T2, xmm0
  and T2, BIT_MASK
  or T2, FLOAT_BITS
  mov REG_%1, T2
  NEXT_INSTRUCTION
%endmacro

I_OPRR_MACRO ADD, add, addsd

HELPER_1ARG I_OPR_MACRO, ADD, add, addsd

HELPER_2ARG I_OP__MACRO, ADD, add, addsd

I_OPRIMACRO ADD, add, addsd

HELPER_1ARG I_OP_IMACRO, ADD, add, addsd

I_OPRR_MACRO SUB, sub, subsd

HELPER_1ARG I_OPR_MACRO, SUB, sub, subsd

HELPER_2ARG I_OP__MACRO, SUB, sub, subsd

;I_OPRIMACRO SUB, sub, subsd

;HELPER_1ARG I_OP_IMACRO, SUB, sub, subsd

I_OPRR_MACRO MUL, imul, mulsd

HELPER_1ARG I_OPR_MACRO, MUL, imul, mulsd

HELPER_2ARG I_OP__MACRO, MUL, imul, mulsd

I_OPRIMACRO MUL, imul, mulsd

HELPER_1ARG I_OP_IMACRO, MUL, imul, mulsd

I_OPRR_MACRO DIV, idiv, divsd

HELPER_1ARG I_OPR_MACRO, DIV, idiv, divsd

HELPER_2ARG I_OP__MACRO, DIV, idiv, divsd

%macro I_NEGATE_MACRO 1
alignment
I_NEGATE%1:
%ifid %1
  mov T0, [CODE_REG + 8]
%define REG_REFERENCE0 REG_ADDR(T0)
%define CODE_ADVANCE 16
  mov T1, REG_REFERENCE0
  test T1, 1
  jnz %%I_NEGATE%{1}__is_float
  neg T1
  mov REG_REFERENCE0, T1
  jmp %%I_NEGATE%{1}__end
%%I_NEGATE%{1}__is_float:
  mov T2, TOP_BIT_64
  xor T1, T2
  mov REG_REFERENCE0, T1
%else
%define REG_REFERENCE0 REG_%1
%define CODE_ADVANCE 8
  test REG_%1, 1
  jnz %%I_NEGATE%{1}__is_float
  neg REG_%1
  jmp %%I_NEGATE%{1}__end
%%I_NEGATE%{1}__is_float:
  mov T2, TOP_BIT_64
  xor REG_%1, T2
%endif
%%I_NEGATE%{1}__end:
  add CODE_REG, CODE_ADVANCE
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_ADVANCE
%endmacro

HELPER_1ARGFULL I_NEGATE_MACRO

alignment
I_JMP:
  add CODE_REG, [CODE_REG + 8]
  NEXT_INSTRUCTION

%macro ADJUST_FLAGS 0
  jnc %%no_carry
  pushf
  or DWORD [rsp], 0x80 ; set sign (overflow is zero, so OF != SF)
  popf
%%no_carry:
%endmacro

alignment
I_CMPRR:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  mov T0, REG_ADDR(T0)
  mov T1, REG_ADDR(T1)
  test T0, 2
  jnz I_CMPRR_arg1_not_float
  test T0, 1
  jnz I_CMPRR_arg1_float
I_CMPRR_arg1_not_float:
  test T1, 2
  jnz I_CMPRR_arg2_not_float
  test T1, 1
  jnz I_CMPRR_arg2_float
I_CMPRR_arg2_not_float:
  cmp T0, T1
  NEXT_INSTRUCTION
I_CMPRR_arg1_float:
  test T1, 1
  jnz I_CMPRR_arg12_float
  FLOAT_REG_TO_XMM T0, T3, xmm0
  INT_REG_TO_XMM T1, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
I_CMPRR_arg2_float:
  INT_REG_TO_XMM T0, xmm0
  FLOAT_REG_TO_XMM T1, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
I_CMPRR_arg12_float:
  FLOAT_REG_TO_XMM T0, T3, xmm0
  FLOAT_REG_TO_XMM T1, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION

%macro I_CMPR_MACRO 1
alignment
I_CMPR%1:
  mov T0, [CODE_REG + 8]
  mov T0, REG_ADDR(T0)
  add CODE_REG, 16
  test T0, 2
  jnz %%I_CMPR%{1}_arg1_not_float
  test T0, 1
  jnz %%I_CMPR%{1}_arg1_float
%%I_CMPR%{1}_arg1_not_float:
  test REG_%{1}, 2
  jnz %%I_CMPR%{1}_arg2_not_float
  test REG_%{1}, 1
  jnz %%I_CMPR%{1}_arg2_float
%%I_CMPR%{1}_arg2_not_float:
  cmp T0, REG_%{1}
  NEXT_INSTRUCTION
%%I_CMPR%{1}_arg1_float:
  test REG_%{1}, 1
  jnz %%I_CMPR%{1}_arg12_float
  FLOAT_REG_TO_XMM T0, T3, xmm0
  INT_REG_TO_XMM REG_%{1}, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%%I_CMPR%{1}_arg2_float:
  INT_REG_TO_XMM T0, xmm0
  FLOAT_REG_TO_XMM REG_%{1}, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%%I_CMPR%{1}_arg12_float:
  FLOAT_REG_TO_XMM T0, T3, xmm0
  FLOAT_REG_TO_XMM REG_%{1}, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION

alignment
I_CMP%{1}R:
  mov T1, [CODE_REG + 8]
  mov T1, REG_ADDR(T1)
  add CODE_REG, 16
  test REG_%{1}, 2
  jnz %%I_CMP%{1}R_arg1_not_float
  test REG_%{1}, 1
  jnz %%I_CMP%{1}R_arg1_float
%%I_CMP%{1}R_arg1_not_float:
  test T1, 2
  jnz %%I_CMP%{1}R_arg2_not_float
  test T1, 1
  jnz %%I_CMP%{1}R_arg2_float
%%I_CMP%{1}R_arg2_not_float:
  cmp REG_%1, T1
  NEXT_INSTRUCTION
%%I_CMP%{1}R_arg1_float:
  test T1, 1
  jnz %%I_CMP%{1}R_arg12_float
  FLOAT_REG_TO_XMM REG_%{1}, T3, xmm0
  INT_REG_TO_XMM T1, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%%I_CMP%{1}R_arg2_float:
  INT_REG_TO_XMM REG_%{1}, T3, xmm0
  FLOAT_REG_TO_XMM T1, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%%I_CMP%{1}R_arg12_float:
  FLOAT_REG_TO_XMM REG_%{1}, T3, xmm0
  FLOAT_REG_TO_XMM T1, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%endmacro

%macro I_CMP__MACRO 2
alignment
I_CMP%1%2:
  add CODE_REG, 8
  test REG_%{1}, 2
  jnz %%I_CMP%{1}%{2}_arg1_not_float
  test REG_%{1}, 1
  jnz %%I_CMP%{1}%{2}_arg1_float
%%I_CMP%{1}%{2}_arg1_not_float:
  test REG_%{2}, 2
  jnz %%I_CMP%{1}%{2}_arg2_not_float
  test REG_%{2}, 1
  jnz %%I_CMP%{1}%{2}_arg2_float
%%I_CMP%{1}%{2}_arg2_not_float:
  cmp REG_%1, REG_%2
  NEXT_INSTRUCTION
%%I_CMP%{1}%{2}_arg1_float:
  test REG_%{2}, 1
  jnz %%I_CMP%{1}%{2}_arg12_float
  FLOAT_REG_TO_XMM REG_%{1}, T3, xmm0
  INT_REG_TO_XMM REG_%{2}, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%%I_CMP%{1}%{2}_arg2_float:
  INT_REG_TO_XMM REG_%{1}, T3, xmm0
  FLOAT_REG_TO_XMM REG_%{2}, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%%I_CMP%{1}%{2}_arg12_float:
  FLOAT_REG_TO_XMM REG_%{1}, T3, xmm0
  FLOAT_REG_TO_XMM REG_%{2}, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%endmacro

HELPER_1ARG I_CMPR_MACRO

HELPER_2ARG I_CMP__MACRO

alignment
I_CMPRI:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  mov T0, REG_ADDR(T0)
  test T0, 2
  jnz I_CMPRI_arg1_not_float
  test T0, 1
  jnz I_CMPRI_arg1_float
I_CMPRI_arg1_not_float:
  cmp T0, T1
  NEXT_INSTRUCTION
I_CMPRI_arg1_float:
  FLOAT_REG_TO_XMM T0, T3, xmm0
  INT_REG_TO_XMM T1, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION

alignment
I_CMPRIF:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  add CODE_REG, 24
  mov T0, REG_ADDR(T0)
  test T0, 2
  jnz I_CMPRIF_arg1_not_float
  test T0, 1
  jnz I_CMPRIF_arg1_float
I_CMPRIF_arg1_not_float:
  INT_REG_TO_XMM T0, xmm0
  FLOAT_REG_TO_XMM T1, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
I_CMPRIF_arg1_float:
  FLOAT_REG_TO_XMM T0, T3, xmm0
  FLOAT_REG_TO_XMM T1, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION

%macro I_CMP_IMACRO 1
alignment
I_CMP%{1}I:
  mov T0, [CODE_REG + 8]
  add CODE_REG, 16
  test REG_%{1}, 2
  jnz %%I_CMP%{1}I_arg1_not_float
  test REG_%{1}, 1
  jnz %%I_CMP%{1}I_arg1_float
%%I_CMP%{1}I_arg1_not_float:
  cmp REG_%{1}, T0
  NEXT_INSTRUCTION
%%I_CMP%{1}I_arg1_float:
  FLOAT_REG_TO_XMM REG_%{1}, T3, xmm0
  INT_REG_TO_XMM T0, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION

alignment
I_CMP%{1}IF:
  mov T0, [CODE_REG + 8]
  add CODE_REG, 16
  test REG_%{1}, 2
  jnz %%I_CMP%{1}IF_arg1_not_float
  test REG_%{1}, 1
  jnz %%I_CMP%{1}IF_arg1_float
%%I_CMP%{1}IF_arg1_not_float:
  INT_REG_TO_XMM REG_%{1}, T3, xmm0
  FLOAT_REG_TO_XMM T0, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%%I_CMP%{1}IF_arg1_float:
  FLOAT_REG_TO_XMM REG_%{1}, T3, xmm0
  FLOAT_REG_TO_XMM T0, T3, xmm1
  comisd xmm0, xmm1
  ADJUST_FLAGS
  NEXT_INSTRUCTION
%endmacro

HELPER_1ARG I_CMP_IMACRO

alignment
I_INC_JMP_LTRR:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  mov T2, REG_ADDR(T0)
  mov T1, REG_ADDR(T1)
  add T2, INTEGER_1
  mov REG_ADDR(T0), T2
  cmp T2, T1
  jge I_INC_JMP_LTRR__1
  add CODE_REG, [CODE_REG + 24]
  NEXT_INSTRUCTION
I_INC_JMP_LTRR__1:
  add CODE_REG, 32
  NEXT_INSTRUCTION

%macro I_INC_JMP_LTR_MACRO 1
alignment
I_INC_JMP_LTR%{1}:
  mov T0, [CODE_REG + 8]
  mov T1, REG_ADDR(T0)
  add T1, INTEGER_1
  mov REG_ADDR(T0), T1
  cmp T1, REG_%1
  jge I_INC_JMP_LTR%{1}__1
  add CODE_REG, [CODE_REG + 16]
  NEXT_INSTRUCTION
I_INC_JMP_LTR%{1}__1:
  add CODE_REG, 24
  NEXT_INSTRUCTION

alignment
I_INC_JMP_LT%{1}R:
  mov T0, [CODE_REG + 8]
  mov T0, REG_ADDR(T0)
  add REG_%1, INTEGER_1
  cmp REG_%1, T0
  jge I_INC_JMP_LT%{1}R__1
  add CODE_REG, [CODE_REG + 16]
  NEXT_INSTRUCTION
I_INC_JMP_LT%{1}R__1:
  add CODE_REG, 24
  NEXT_INSTRUCTION
%endmacro

%macro I_INC_JMP_LT__MACRO 2
alignment
I_INC_JMP_LT%{1}%{2}:
  add REG_%1, INTEGER_1
  cmp REG_%1, REG_%2
  jge I_INC_JMP_LT%{1}%{2}__1
  add CODE_REG, [CODE_REG + 8]
  NEXT_INSTRUCTION
I_INC_JMP_LT%{1}%{2}__1:
  add CODE_REG, 16
  NEXT_INSTRUCTION
%endmacro

HELPER_1ARG I_INC_JMP_LTR_MACRO

HELPER_2ARG I_INC_JMP_LT__MACRO

%macro jmp_comp 2
alignment
I_JMP_%1:
  %2 I_JMP_%{1}__1
  add CODE_REG, 16
  NEXT_INSTRUCTION
I_JMP_%{1}__1:
  add CODE_REG, [CODE_REG + 8]
  NEXT_INSTRUCTION
%endmacro

HELPER_COND jmp_comp

%macro I_RETC_MACRO 1
alignment
I_RETC%1:
%ifid %1 ; if identifier (R)
  mov T0, [CODE_REG + 8]
  mov rax, REG_ADDR(T0)
%else
  mov rax, REG_%1
%endif
  mov rbx, RBX_STACK_LOC
  mov rsp, rbp
  pop r15
  pop r14
  pop r13
  pop r12
%ifdef WIN32_CALLING_CONVENTION
  pop rsi
  pop rdi
%endif
  pop rbp
  ret
%endmacro

HELPER_1ARGFULL I_RETC_MACRO

%macro I_RET_MACRO 1
alignment
I_RET%1:
%ifid %1
  mov T0, [CODE_REG + 8]
  ;mov T1, [CODE_REG + 16]
%define REG_REFERENCE0 REG_ADDR(T0)
%else
  ;mov T1, [CODE_REG + 8]
%define REG_REFERENCE0 REG_%1
%endif
  mov rax, REG_REFERENCE0
  add STACK_REG, [STACK_REG] ; restore stack reg
  mov CODE_REG, [STACK_REG + 8]
  add STACK_REG, 16 ; undo I_CALL
  pop REG_2
  pop REG_2
  pop REG_1
  pop REG_0
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%endmacro

HELPER_1ARGFULL I_RET_MACRO

alignment
I_CALL:
  mov T0, [CODE_REG + 8] ; function object
  and T0, BIT_MASK ; get pointer
%ifdef TRACE_CALL
  push T0
  push T0
  mov ARG_REG_0, T0
  PRE_FUNCTION_CALL
  call trace_function
  POST_FUNCTION_CALL
  pop T0
  pop T0
%endif
  mov T1, [T0 + FUNCTION_PTR_OFFSET] ; ptr to bytecode
  add CODE_REG, 16
  sub STACK_REG, 16
  mov [STACK_REG + 8], CODE_REG ; save code position for the next instruction to stack
  mov [STACK_REG], T0 ; save function object pointer
  push REG_0 ; function will use these registers so we need to save them
  push REG_1
  push REG_2
  push REG_2
  mov CODE_REG, T1 ; go to bytecode of the function
  NEXT_INSTRUCTION

%macro I_CALLINT_MACRO 1
alignment
I_CALLINT%1:
%ifidn %1,N
%define CODE_OFFSET 0
%define NEED_RESULT 0
%elifidn %1,R
%define CODE_OFFSET 8
%define NEED_RESULT 1
%else
%define CODE_OFFSET 0
%define NEED_RESULT 1
%endif
%define CODE_ADVANCE (CODE_OFFSET + 24)
  mov T0, [CODE_REG + CODE_OFFSET + 8] ; function object
  and T0, BIT_MASK ; get pointer
  mov T1, [T0 + FUNCTION_PTR_OFFSET] ; ptr to function
  mov rax, T1
  mov ARG_REG_0, INTERP_STACK_LOC ; arg0 (pointer to interpreter struct)
  mov ARG_REG_1, STACK_REG ; arg1 (pointer to stack)
  mov ARG_REG_2, [CODE_REG + CODE_OFFSET + 16] ; arg2 (number of arguments)
  mov ARG_REG_3, NEED_RESULT ; arg3 (0/1 - result needed)
  PRE_FUNCTION_CALL
  call rax ; call the function
  POST_FUNCTION_CALL
%ifidn %1,N
  ; no need to store result
%elifidn %1,R
  mov T0, [CODE_REG + 8] ; result register
  mov REG_ADDR(T0), rax
%else
  mov REG_%1, rax
%endif
  add CODE_REG, CODE_ADVANCE
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_ADVANCE
%undef CODE_OFFSET
%undef NEED_RESULT
%endmacro

; version without result
I_CALLINT_MACRO N

HELPER_1ARGFULL I_CALLINT_MACRO

%macro CONVERT_TO_C 1
  test %1, 1
  jnz %%not_num
  sar %1, INTEGER_SHIFT
  jmp %%end
%%not_num:
  test %1, 2
  jz %%not_num_float
  and %1, BIT_MASK ; get pointer
  mov %1, [%1 + ARRAY_STORAGE_OFFSET] ; get pointer to data (array/string)
%%not_num_float:
%%end:
%endmacro

%macro I_CALLEXT_MACRO 1
alignment
I_CALLEXT%1:
%ifidn %1,N
%define CODE_OFFSET 0
%define NEED_RESULT 0
%elifidn %1,R
%define CODE_OFFSET 8
%define NEED_RESULT 1
%else
%define CODE_OFFSET 0
%define NEED_RESULT 1
%endif
%define CODE_ADVANCE (CODE_OFFSET + 24)
  mov T0, [CODE_REG + CODE_OFFSET + 8] ; function object
  and T0, BIT_MASK ; get pointer
  mov T1, [T0 + FUNCTION_PTR_OFFSET] ; ptr to function
  mov rax, T1
  mov T0, [CODE_REG + CODE_OFFSET + 16] ; num arguments
  cmp T0, 0
  je %%arg0
  cmp T0, 1
  je %%arg1
  cmp T0, 2
  je %%arg2
  cmp T0, 3
  je %%arg3
  cmp T0, 4
  je %%arg4
%ifndef WIN32_CALLING_CONVENTION
  cmp T0, 5
  je %%arg5
  cmp T0, 6
  je %%arg6
%%arg6:
  mov ARG_REG_5, [STACK_REG + STACK_TOP_PADDING + 40]
  CONVERT_TO_C ARG_REG_5
%%arg5:
  mov ARG_REG_4, [STACK_REG + STACK_TOP_PADDING + 32]
  CONVERT_TO_C ARG_REG_4
%endif
%%arg4:
  mov ARG_REG_3, [STACK_REG + STACK_TOP_PADDING + 24]
  CONVERT_TO_C ARG_REG_3
%%arg3:
  mov ARG_REG_2, [STACK_REG + STACK_TOP_PADDING + 16]
  CONVERT_TO_C ARG_REG_2
%%arg2:
  mov ARG_REG_1, [STACK_REG + STACK_TOP_PADDING + 8]
  CONVERT_TO_C ARG_REG_1
%%arg1:
  mov ARG_REG_0, [STACK_REG + STACK_TOP_PADDING]
  CONVERT_TO_C ARG_REG_0
%%arg0:
  PRE_FUNCTION_CALL
  call rax ; call the function
  POST_FUNCTION_CALL
%ifidn %1,N
  ; no need to store result
%elifidn %1,R
  sal rax, INTEGER_SHIFT ; convert to number
  mov T0, [CODE_REG + 8] ; result register
  mov REG_ADDR(T0), rax
%else
  mov REG_%1, rax
  sal REG_%1, INTEGER_SHIFT ; convert to number
%endif
  add CODE_REG, CODE_ADVANCE
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_ADVANCE
%undef CODE_OFFSET
%undef NEED_RESULT
%endmacro

; version without result
I_CALLEXT_MACRO N

HELPER_1ARGFULL I_CALLEXT_MACRO

%macro I_MOVERETVAL_MACRO 1
alignment
I_MOVERETVAL%1:
%ifid %1
  mov T0, [CODE_REG + 8]
%define REG_REFERENCE0 REG_ADDR(T0)
%define CODE_ADVANCE 16
%else
%define REG_REFERENCE0 REG_%1
%define CODE_ADVANCE 8
%endif
  mov REG_REFERENCE0, rax
  add CODE_REG, CODE_ADVANCE
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_ADVANCE
%endmacro

HELPER_1ARGFULL I_MOVERETVAL_MACRO

%macro I_INCREF_MACRO 1
alignment
I_INCREF%1:
%ifid %1
  mov T0, [CODE_REG + 8]
%define REG_REFERENCE0 REG_ADDR(T0)
%define CODE_ADVANCE 16
%else
%define REG_REFERENCE0 REG_%1
%define CODE_ADVANCE 8
%endif
  mov T0, REG_REFERENCE0
  add CODE_REG, CODE_ADVANCE
  ; check if it is reference counted
  JUMP_NOT_REFERENCE_COUNTED T0, T2, I_INCREF%1__1
  and T0, BIT_MASK ; get pointer
  mov T2, 1
  lock xadd QWORD [T0], T2 ; increment by one
I_INCREF%1__1:
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_ADVANCE
%endmacro

HELPER_1ARGFULL I_INCREF_MACRO
  
%macro I_DECREF_MACRO 1
alignment
I_DECREF%1:
%ifid %1
  mov T0, [CODE_REG + 8]
%define REG_REFERENCE0 REG_ADDR(T0)
%define CODE_ADVANCE 16
%else
%define REG_REFERENCE0 REG_%1
%define CODE_ADVANCE 8
%endif
  mov T0, REG_REFERENCE0
  add CODE_REG, CODE_ADVANCE
  ; check if it is reference counted
  JUMP_NOT_REFERENCE_COUNTED T0, T2, I_DECREF%1__1
  and T0, BIT_MASK ; get pointer
  mov T2, 1
  neg T2
  lock xadd QWORD [T0], T2 ; not operation width
%ifdef DEBUG_DECREF
  ;; DEBUG - check if refcount was already 0
  cmp T2, 0
  jne I_DECREF%1__2
  int3
  nop
I_DECREF%1__2:
%endif
  cmp T2, 1
  jnz I_DECREF%1__1
  ; count is 0, free object
  mov ARG_REG_0, INTERP_STACK_LOC ; arg0
  add T0, 3
  mov ARG_REG_1, T0 ; arg1 - object
  PRE_FUNCTION_CALL
  call free_object ; free the object
  POST_FUNCTION_CALL
I_DECREF%1__1:
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_ADVANCE
%endmacro

HELPER_1ARGFULL I_DECREF_MACRO

%macro I_AINDEX_DO_MACRO 0 ; T0 array object, T1 index, read value from the index
  and T0, BIT_MASK
  mov T2, [T0 + ARRAY_READ_BYTECODE_OFFSET]
  mov T0, [T0 + ARRAY_STORAGE_OFFSET]
  sar T1, INTEGER_SHIFT
  jmp T2
%endmacro

alignment
I_AINDEXRR:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  mov T0, REG_ADDR(T0)
  mov T1, REG_ADDR(T1)
  add CODE_REG, 24
  I_AINDEX_DO_MACRO

%macro I_AINDEXR_MACRO 1
alignment
I_AINDEXR%1:
  mov T0, [CODE_REG + 8]
  mov T1, REG_%1
  mov T0, REG_ADDR(T0)
  add CODE_REG, 16
  I_AINDEX_DO_MACRO

alignment
I_AINDEX%{1}R:
  mov T1, [CODE_REG + 8]
  mov T0, REG_%1
  mov T1, REG_ADDR(T1)
  add CODE_REG, 16
  I_AINDEX_DO_MACRO
%endmacro

%macro I_AINDEX__MACRO 2
alignment
I_AINDEX%1%2:
  mov T0, REG_%1
  mov T1, REG_%2
  add CODE_REG, 8
  I_AINDEX_DO_MACRO
%endmacro

HELPER_1ARG I_AINDEXR_MACRO

HELPER_2ARG I_AINDEX__MACRO

alignment
I_AINDEXRI:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  mov T0, REG_ADDR(T0)
  add CODE_REG, 24
  I_AINDEX_DO_MACRO

%macro I_AINDEX_IMACRO 1
alignment
I_AINDEX%{1}I:
  mov T0, REG_%1
  mov T1, [CODE_REG + 8]
  add CODE_REG, 16
  I_AINDEX_DO_MACRO
%endmacro

HELPER_1ARG I_AINDEX_IMACRO

alignment
I_SAINDEXRR:
  mov T0, [CODE_REG + 8]
  mov T1, [CODE_REG + 16]
  mov T0, REG_ADDR(T0)
  mov T1, REG_ADDR(T1)
  add CODE_REG, 24
  sar T1, INTEGER_SHIFT
  NEXT_INSTRUCTION

%macro I_SAINDEXR_MACRO 1
alignment
I_SAINDEXR%1:
  mov T0, [CODE_REG + 8]
  mov T1, REG_%1
  mov T0, REG_ADDR(T0)
  add CODE_REG, 16
  sar T1, INTEGER_SHIFT
  NEXT_INSTRUCTION

alignment
I_SAINDEX%{1}R:
  mov T1, [CODE_REG + 8]
  mov T0, REG_%1
  mov T1, REG_ADDR(T1)
  add CODE_REG, 16
  sar T1, INTEGER_SHIFT
  NEXT_INSTRUCTION
%endmacro

%macro I_SAINDEX__MACRO 2
alignment
I_SAINDEX%1%2:
  mov T0, REG_%1
  mov T1, REG_%2
  add CODE_REG, 8
  sar T1, INTEGER_SHIFT
  NEXT_INSTRUCTION
%endmacro

HELPER_1ARG I_SAINDEXR_MACRO

HELPER_2ARG I_SAINDEX__MACRO

I_READ_OBJ:
  mov T1, [T0 + 8 * T1]
  mov rax, T1
  TESTINCREF T1, T0 ; incref the value
  NEXT_INSTRUCTION

I_READ_I1:
  xor rax, rax
  mov al, [T0 + T1]
  sal eax, INTEGER_SHIFT ; convert to number
  NEXT_INSTRUCTION

I_READ_U1:
  xor rax, rax
  mov al, [T0 + T1]
  sal eax, INTEGER_SHIFT ; convert to number
  NEXT_INSTRUCTION

I_READ_I2:
  movsx rax, WORD [T0 + 2 * T1]
  sal rax, INTEGER_SHIFT ; convert to number
  NEXT_INSTRUCTION

I_READ_U2:
  movzx rax, WORD [T0 + 2 * T1]
  sal rax, INTEGER_SHIFT ; convert to number
  NEXT_INSTRUCTION

I_READ_I4:
  movsxd rax, [T0 + 4 * T1]
  sal rax, INTEGER_SHIFT ; convert to number
  NEXT_INSTRUCTION

I_READ_U4:
  mov eax, [T0 + 4 * T1]
  sal rax, INTEGER_SHIFT ; convert to number
  NEXT_INSTRUCTION

I_READ_I8:
I_READ_U8:
  mov rax, [T0 + 8 * T1]
  sal rax, INTEGER_SHIFT ; convert to number
  NEXT_INSTRUCTION

I_READ_F4:
  movss FLOAT_REG_TMP, [T0 + 4 * T1]
  cvtss2sd FLOAT_REG_TMP, FLOAT_REG_TMP
  movq rax, FLOAT_REG_TMP
  and rax, BIT_MASK
  or rax, FLOAT_BITS
  NEXT_INSTRUCTION

I_READ_F8:
  mov rax, [T0 + 8 * T1]
  and rax, BIT_MASK
  or rax, FLOAT_BITS
  NEXT_INSTRUCTION

%macro I_SAVALUE_MACRO 1
alignment
I_SAVALUE%1:
%ifid %1 ; if identifier (R)
  mov T2, [CODE_REG + 8]
  mov rax, REG_ADDR(T2)
%define CODE_ADVANCE 16
%else
  mov rax, REG_%1
%define CODE_ADVANCE 8
%endif
  add CODE_REG, CODE_ADVANCE
  and T0, BIT_MASK
  mov T3, [T0 + ARRAY_STORE_BYTECODE_OFFSET]
  mov T0, [T0 + ARRAY_STORAGE_OFFSET]
  jmp T3 ; jump to store byte with T0 = ptr to storage, T1 = idx
  NEXT_INSTRUCTION
%undef CODE_ADVANCE
%endmacro

HELPER_1ARGFULL I_SAVALUE_MACRO

I_STORE_OBJ:
  lea T0, [T0 + 8 * T1] ; store address
  mov T0_STACK_LOC, T0
  mov T_RAX_STACK_LOC, rax
  mov T1, [T0] ; read previous value
  TESTDECREF T1, T0
  mov T0, T0_STACK_LOC
  mov rax, T_RAX_STACK_LOC
  mov [T0], rax ; store 8 byte at address T0
  NEXT_INSTRUCTION

I_STORE_I1:
  ; convert to 8 bit integer
  sar rax, INTEGER_SHIFT
  mov [T0 + T1], al ; store 1 byte at address T0 + T1 (set by previous bytecode)
  NEXT_INSTRUCTION

I_STORE_U1:
  ; convert to 8 bit integer
  sar rax, INTEGER_SHIFT
  mov [T0 + T1], al ; store 1 byte at address T0 + T1 (set by previous bytecode)
  NEXT_INSTRUCTION

I_STORE_I2:
I_STORE_U2:
  sar rax, INTEGER_SHIFT
  mov [T0 + 2 * T1], ax ; store 2 byte at address T0, index T1
  NEXT_INSTRUCTION

I_STORE_I4:
I_STORE_U4:
  sar rax, INTEGER_SHIFT
  mov [T0 + 4 * T1], eax ; store 4 byte at address T0, index T1
  NEXT_INSTRUCTION

I_STORE_I8:
  sar rax, INTEGER_SHIFT
  mov [T0 + 8 * T1], rax ; store 8 byte at address T0, index T1
  NEXT_INSTRUCTION

I_STORE_U8:
  sar rax, INTEGER_SHIFT
  mov [T0 + 8 * T1], rax ; store 8 byte at address T0, index T1
  NEXT_INSTRUCTION

I_STORE_F4:
  test rax, 1
  jz I_STORE_F4_number
  test rax, 2
  jnz I_STORE_F4_other
  and rax, BIT_MASK
  movq FLOAT_REG_TMP, rax
  cvtsd2ss FLOAT_REG_TMP, FLOAT_REG_TMP
  movss [T0 + 4 * T1], FLOAT_REG_TMP ; store 4 byte at address T0, index T1 (set by previous bytecode)
I_STORE_F4_number:
I_STORE_F4_other:
  NEXT_INSTRUCTION

I_STORE_F8:
  test rax, 1
  jz I_STORE_F8_number
  test rax, 2
  jnz I_STORE_F8_other
  and rax, BIT_MASK
  or rax, FLOAT_BITS
  mov [T0 + 8 * T1], rax ; store 8 byte at address T0, index T1 (set by previous bytecode)
I_STORE_F8_number:
I_STORE_F8_other:
  NEXT_INSTRUCTION

%macro I_ULONGARG_MACRO 2
alignment
I_ULONGARG%{1}%{2}:
%ifidn %{1},R
%define CODE_OFFSET 8
%else
%define CODE_OFFSET 0
%endif
%ifidn %{2},I
%define CODE_OFFSET2 8
  mov rax, [CODE_REG + CODE_OFFSET + 8]
%elifidn %{2},R
%define CODE_OFFSET2 8
  mov rax, [CODE_REG + CODE_OFFSET + 8]
  mov rax, REG_ADDR(rax)
%else
%define CODE_OFFSET2 0
  mov rax, REG_%{2}
%endif
  sar rax, INTEGER_SHIFT ; convert to number
%ifidn %{1},R
  mov T1_STACK_LOC, T1
  mov T1, [CODE_REG + 8]
%ifndef WIN32_CALLING_CONVENTION
  sub T1, 6 ; 6 values passed in registers, idx 6 is the first on stack
%endif
  mov [rsp + T1 * 8], rax ; move to stack
  mov T1, T1_STACK_LOC
%else
  mov ARG_REG_%{1}, rax ; move directly to a register
%endif
  add CODE_REG, (CODE_OFFSET + CODE_OFFSET2 + 8)
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_OFFSET
%endmacro

HELPER_ARG I_ULONGARG_MACRO

%macro I_PTRARG_MACRO 2
alignment
I_PTRARG%{1}%{2}:
%ifidn %{1},R
%define CODE_OFFSET 8
%else
%define CODE_OFFSET 0
%endif
%ifidn %{2},I
%define CODE_OFFSET2 8
  mov rax, [CODE_REG + CODE_OFFSET + 8]
%elifidn %{2},R
%define CODE_OFFSET2 8
  mov rax, [CODE_REG + CODE_OFFSET + 8]
  mov rax, REG_ADDR(rax)
%else
%define CODE_OFFSET2 0
  mov rax, REG_%{2}
%endif
  and rax, BIT_MASK
  mov rax, [rax + ARRAY_STORAGE_OFFSET]
%ifidn %{1},R
  mov T1_STACK_LOC, T1
  mov T1, [CODE_REG + 8]
%ifndef WIN32_CALLING_CONVENTION
  sub T1, 6 ; 6 values passed in registers, idx 6 is the first on stack
%endif
  mov [rsp + T1 * 8], rax ; move to stack
  mov T1, T1_STACK_LOC
%else
  mov ARG_REG_%{1}, rax ; move directly to a register
%endif
  add CODE_REG, (CODE_OFFSET + CODE_OFFSET2 + 8)
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_OFFSET
%endmacro

HELPER_ARG I_PTRARG_MACRO

%macro I_F4ARG_MACRO 2
alignment
I_F4ARG%{1}%{2}:
%ifidn %{1},R
%define CODE_OFFSET 8
%else
%define CODE_OFFSET 0
%endif
%ifidn %{2},I
%define CODE_OFFSET2 8
  mov rax, [CODE_REG + CODE_OFFSET + 8]
%elifidn %{2},R
%define CODE_OFFSET2 8
  mov rax, [CODE_REG + CODE_OFFSET + 8]
  mov rax, REG_ADDR(rax)
%else
%define CODE_OFFSET2 0
  mov rax, REG_%{2}
%endif
  test rax, 1 ; check if integer
  jz %%I_F4ARG%{1}%{2}_int_arg
  and rax, BIT_MASK
%ifidn %{1},R
  ; convert to float
  movq FLOAT_REG_TMP, rax
  cvtsd2ss FLOAT_REG_TMP, FLOAT_REG_TMP
  mov T1_STACK_LOC, T1
  mov T1, [CODE_REG + 8]
%ifndef WIN32_CALLING_CONVENTION
  sub T1, 8 ; 8 floating point values passed in registers, idx 8 is the first on stack
%endif
  movss [rsp + T1 * 8], FLOAT_REG_TMP ; move to stack
  mov T1, T1_STACK_LOC
%else
  movq FLOAT_ARG_REG_%{1}, rax ; move directly to a register
  cvtsd2ss FLOAT_ARG_REG_%{1}, FLOAT_ARG_REG_%{1}
%endif
  add CODE_REG, (CODE_OFFSET + CODE_OFFSET2 + 8)
  NEXT_INSTRUCTION
%%I_F4ARG%{1}%{2}_int_arg:
  sar rax, INTEGER_SHIFT
%ifidn %{1},R
  ; convert int to float
  cvtsi2ss FLOAT_REG_TMP, rax
  mov T1_STACK_LOC, T1
  mov T1, [CODE_REG + 8]
  sub T1, 8
  movss [rsp + T1 * 8], FLOAT_REG_TMP ; move to stack
  mov T1, T1_STACK_LOC
%else
  cvtsi2ss FLOAT_ARG_REG_%{1}, rax ; convert directly to a register
%endif
  add CODE_REG, (CODE_OFFSET + CODE_OFFSET2 + 8)
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_OFFSET
%endmacro

HELPER_ARG_FLOAT I_F4ARG_MACRO

%macro I_F8ARG_MACRO 2
alignment
I_F8ARG%{1}%{2}:
%ifidn %{1},R
%define CODE_OFFSET 8
%else
%define CODE_OFFSET 0
%endif
%ifidn %{2},I
%define CODE_OFFSET2 8
  mov rax, [CODE_REG + CODE_OFFSET + 8]
%elifidn %{2},R
%define CODE_OFFSET2 8
  mov rax, [CODE_REG + CODE_OFFSET + 8]
  mov rax, REG_ADDR(rax)
%else
%define CODE_OFFSET2 0
  mov rax, REG_%{2}
%endif
  test rax, 1 ; check if integer
  jz %%I_F8ARG%{1}%{2}_int_arg
  and rax, BIT_MASK
%ifidn %{1},R
  mov T1_STACK_LOC, T1
  mov T1, [CODE_REG + 8]
%ifndef WIN32_CALLING_CONVENTION
  sub T1, 8 ; 8 floating point values passed in registers, idx 8 is the first on stack
%endif
  mov [rsp + T1 * 8], rax ; move to stack
  mov T1, T1_STACK_LOC
%else
  movq FLOAT_ARG_REG_%{1}, rax ; move directly to a register
%endif
  add CODE_REG, (CODE_OFFSET + CODE_OFFSET2 + 8)
  NEXT_INSTRUCTION
%%I_F8ARG%{1}%{2}_int_arg:
  sar rax, INTEGER_SHIFT
%ifidn %{1},R
  ; convert int to float
  cvtsi2sd FLOAT_REG_TMP, rax
  mov T1_STACK_LOC, T1
  mov T1, [CODE_REG + 8]
  sub T1, 8
  movq [rsp + T1 * 8], FLOAT_REG_TMP ; move to stack
  mov T1, T1_STACK_LOC
%else
  cvtsi2sd FLOAT_ARG_REG_%{1}, rax ; convert directly to a register
%endif
  add CODE_REG, (CODE_OFFSET + CODE_OFFSET2 + 8)
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_OFFSET
%endmacro

HELPER_ARG_FLOAT I_F8ARG_MACRO

%macro I_CALLEXT2_MACRO 1
alignment
I_CALLEXT2%1:
%ifidn %1,N
%define CODE_OFFSET 0
%define NEED_RESULT 0
%elifidn %1,R
%define CODE_OFFSET 8
%define NEED_RESULT 1
%else
%define CODE_OFFSET 0
%define NEED_RESULT 1
%endif
%define CODE_ADVANCE (CODE_OFFSET + 24)
  mov T0_STACK_LOC, T0
  mov T0, [CODE_REG + CODE_OFFSET + 8] ; function object
  and T0, BIT_MASK ; get pointer
  mov rax, [T0 + FUNCTION_PTR_OFFSET] ; ptr to function
  mov T0, T0_STACK_LOC
  call rax ; call the function
  add rsp, [CODE_REG + CODE_OFFSET + 16] ; move rsp back
  sal rax, INTEGER_SHIFT ; convert to number
%ifidn %1,N
  ; no need to store result
%elifidn %1,R
  mov T0, [CODE_REG + 8] ; result register
  mov REG_ADDR(T0), rax
%else
  mov REG_%1, rax
%endif
  add CODE_REG, CODE_ADVANCE
  NEXT_INSTRUCTION
%undef REG_REFERENCE0
%undef CODE_ADVANCE
%undef CODE_OFFSET
%undef NEED_RESULT
%endmacro

; version without result
I_CALLEXT2_MACRO N

HELPER_1ARGFULL I_CALLEXT2_MACRO

alignment
I_CALLEXT2_PREPARE:
  sub rsp, [CODE_REG + 8] ; stack allocation in bytes
  add CODE_REG, 16
  NEXT_INSTRUCTION

alignment
I_DEBUG_BREAK:
  add CODE_REG, 8
  int3
  NEXT_INSTRUCTION

