/**
 * Rex
 *
 * Lisp like language with a fast register bytecode VM
 *
 * Author: Ziga Lenarcic
 */
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <stdarg.h>
#include <math.h>
#include <errno.h>

#ifdef _MSC_VER
#define M_PI 3.141592653589793
#else
#include <sys/time.h>
#include <sys/mman.h>
#endif

#include "basicslib.h"

// #define DEBUG_REFCOUNT

#ifdef _WIN32
#define WIN32_CALLING_CONVENTION
#define NUM_INT_REG_ARGUMENTS 4
#define NUM_FLOAT_REG_ARGUMENTS 4
#define NUM_REG_ARGUMENTS 4
#else
#define NUM_INT_REG_ARGUMENTS 6
#define NUM_FLOAT_REG_ARGUMENTS 8
#endif

#define PATH_SEPARATOR '/'

/*
 * Typedefs
 */
typedef void u0;
typedef char i1;
typedef unsigned char u1;
typedef short i2;
typedef unsigned short u2;
typedef int i4;
typedef unsigned int u4;
typedef long long i8;
typedef unsigned long long u8;
typedef float f4;
typedef double f8;
typedef u8 obj;

enum {
  TYPE_ARRAY = 1,
  TYPE_SYMBOL = 2,
  TYPE_FUNCTION = 3,
};

typedef struct allocated_header_t
{
  u8 ref_count;
  u8 type;
} allocated_header_t;

typedef struct array_t
{
  allocated_header_t header;
  u0 *storage;
  u8 size;
  i8 element_type;
  u8 read_bytecode;
  u8 store_bytecode;
  u8 storage_size;
  u8 element_size;
} array_t;

typedef struct symbol_t
{
  allocated_header_t header;
  obj value;
  obj function_value;
  i8 flags;
  i1 *name;
} symbol_t;

enum
{
  SF_HAS_VALUE = 1,
  SF_VALUE_CONST = (1 << 1),
  SF_HAS_FUNCTION_VALUE = (1 << 2),
};

enum FUNCTION_TYPE {
  FT_BUILTIN = 0,
  FT_BYTECODE,
  FT_EXT,
  FT_EXT_PROTOTYPE,
};

typedef struct function_t
{
  allocated_header_t header;
  u0 *ptr;
  u8 function_type;
  i8 min_arg_count;
  i8 max_arg_count;
  obj immediates;
  obj arg_types;
  obj code;
  obj ir_code;
  i8 bytecode_count;
} function_t;

#define MAX_SYMBOLS (4 * 1024)
#if 0
typedef struct {
  obj symbol[MAX_SYMBOLS];
  obj value[MAX_SYMBOLS];
  i1 is_const[MAX_SYMBOLS];
  obj function_value[MAX_SYMBOLS];
  i1 is_function_value_const[MAX_SYMBOLS];
  i8 count;
} globals_t;
#endif

enum {
  VAR_ARGUMENT = 0,
  VAR_LEXICAL,
  VAR_TEMPORARY,
  VAR_CALL_ARGUMENT
};

typedef struct {
  vec_t *bytecode;
  obj immediates;
  u1 *machinecode;
  i8 machinecodepos;

  obj ir_code;

  //globals_t *glob;

  i8 gensym_counter;
  i8 label_counter;

  /* all variables during compilation - this is the index used in IR code */
  struct {
    i8 kind;
    i8 var_sequence_number;
    obj sym;
    i8 is_const;
    obj value; /* if knowable */
    i8 stack_pos; /* where is it stored */
  } vars[1024 * 10];

  i8 vars_count;

  /* program variables - accessible by code through symbols */
  struct {
    obj sym;
    i8 var_idx; /* index into vars array */
  } lexical_vars[1024 * 10];
  i8 lexical_vars_pos;

  i8 lexical_frames[1024]; /* stack of lexical_vars_pos for various scopes */
  i8 lexical_frames_pos;

  i8 loops[1024][2];
  i8 loops_pos;

  i8 register_file_start;
  i8 register_file_end;
} compiler_state;

enum {
  CR_NONE = -2,
  CR_ERROR = -1,
  CR_IMMEDIATE = 0,
  CR_VARIABLE = 1,
  CR_CONDITION = 2,
};

typedef struct {
  i8 type;
  i8 var_idx;
  obj immediate_val;
  i8 condition;
  i8 condition_var_idx1;
  i8 condition_var_idx2;
  i1 contains_function_call;
  i1 str[128];
} compile_result;

/*
 * Macros
 */
#define FMT(stream, ...) print_stream((stream), __VA_ARGS__)
#define SNPRINTF(...) print_string(__VA_ARGS__)
#define FLUSH_STREAM(stream) flush_stream((stream));

#define PRINT_ERROR(...) do { FMT(STDERR_H, "%s: ", __func__); FMT(STDERR_H, __VA_ARGS__); } while (0)

#define INTEGER_SHIFT_WIDTH 1
#define MAKE_INTEGER(i) ((obj)((i8)(i) << INTEGER_SHIFT_WIDTH))
#define MAKE_REAL(x) ((obj)(((u8)f8_to_u8_binary(x) & 0xfffffffffffffffcull) | 0x1))
#define MAKE_ALLOCATED(ptr) ((u8)(ptr) | 0x3)
#define MAKE_VEC(ptr) (MAKE_ALLOCATED(ptr))
#define MAKE_SYMBOL(ptr) (MAKE_ALLOCATED(ptr))

#define NONE_VALUE ((obj)0x3)

#define GET_INTEGER(x) ((i8)(x) >> INTEGER_SHIFT_WIDTH)
#define TO_F8(x) (u8_to_f8_binary((x) & 0xfffffffffffffffcull))
#define GET_POINTER(x) ((allocated_header_t *)((u8)(x) & 0xfffffffffffffffcull))
#define GET_ARR(x) ((array_t *)GET_POINTER(x))
#define GET_SYMBOL(x) ((symbol_t *)GET_POINTER(x))
#define GET_FUNCTION(x) ((function_t *)GET_POINTER(x))
#define GET_ARRAY_STORAGE(type, x) ((type *)GET_ARR(x)->storage)
#define GET_STRING_STORAGE(x) GET_ARRAY_STORAGE(i1, x)
#define GET_ARRAY_ELEMENT_TYPE(x) (GET_ARR(x)->element_type)

#define IS_INTEGER(x) (((x) & 0x1) == 0x0)
#define IS_REAL(x) (((x) & 0x3) == 0x1)
#define IS_NONE(x) ((x) == NONE_VALUE)
#define IS_ALLOCATED(x) (((x) & 0x3) == 0x3 && !IS_NONE(x))

#define IS_ALLOCATED_OF_TYPE(x, ty) (IS_ALLOCATED((x)) && (GET_POINTER((x))->type == (ty)))
#define IS_ARRAY(x) (IS_ALLOCATED_OF_TYPE((x), TYPE_ARRAY))
#define IS_OBJ_ARRAY(x) (IS_ARRAY(x) && (GET_ARRAY_ELEMENT_TYPE(x) == ET_ANY))
#define IS_STRING(x) (IS_ARRAY(x) && (GET_ARRAY_ELEMENT_TYPE(x) == ET_STRING))
#define IS_SYMBOL(x) (IS_ALLOCATED_OF_TYPE((x), TYPE_SYMBOL))
#define IS_FUNCTION(x) (IS_ALLOCATED_OF_TYPE((x), TYPE_FUNCTION))

#define ASIZE(x) (GET_ARR(x)->size)
#define STRSIZE(x) ASIZE(x)
#define NTH_TYPE(type, x, i) (GET_ARRAY_STORAGE(type, x)[(i)])
#define NTH(x, i) NTH_TYPE(obj, x, i)

#define ID(x) x

#define WARN(...) do { FMT(STDERR_H, "Compile warning: "); FMT(STDERR_H, __VA_ARGS__); FMT(STDERR_H, "\n"); } while(0)

// TODO: implement (drop to debugger)
#define RUNTIME_ERROR(...) do { FMT(STDERR_H, __VA_ARGS__); FMT(STDERR_H, "\n"); } while (0)

#define IS_REF_COUNTED(o) (IS_ALLOCATED((o)) && !IS_SYMBOL((o)))
#define INC(interp, o) inc_ref(interp, o)
#define DEC(interp, o) dec_ref(interp, o)

#define NUM_CPU_REGISTERS 3

#define INST_HELPER_1(base, ending, X) \
  X(base##R##ending), \
  X(base##0##ending), \
  X(base##1##ending), \
  X(base##2##ending)

#define INST_HELPER_2(base, X) \
  X(base##RR), \
  X(base##R0), \
  X(base##0R), \
  X(base##R1), \
  X(base##1R), \
  X(base##R2), \
  X(base##2R), \
  X(base##00), \
  X(base##01), \
  X(base##02), \
  X(base##10), \
  X(base##11), \
  X(base##12), \
  X(base##20), \
  X(base##21), \
  X(base##22)

#ifdef WIN32_CALLING_CONVENTION // 4 int regs, 4 floating point regs
#define INST_HELPER_ARG(base, X) \
  X(base##RR), \
  X(base##0R), \
  X(base##1R), \
  X(base##2R), \
  X(base##3R), \
  X(base##R0), \
  X(base##00), \
  X(base##10), \
  X(base##20), \
  X(base##30), \
  X(base##R1), \
  X(base##01), \
  X(base##11), \
  X(base##21), \
  X(base##31), \
  X(base##R2), \
  X(base##02), \
  X(base##12), \
  X(base##22), \
  X(base##32), \
  X(base##RI), \
  X(base##0I), \
  X(base##1I), \
  X(base##2I), \
  X(base##3I)

#define INST_HELPER_ARG_REAL(base, X) \
  X(base##RR), \
  X(base##0R), \
  X(base##1R), \
  X(base##2R), \
  X(base##3R), \
  X(base##R0), \
  X(base##00), \
  X(base##10), \
  X(base##20), \
  X(base##30), \
  X(base##R1), \
  X(base##01), \
  X(base##11), \
  X(base##21), \
  X(base##31), \
  X(base##R2), \
  X(base##02), \
  X(base##12), \
  X(base##22), \
  X(base##32), \
  X(base##RI), \
  X(base##0I), \
  X(base##1I), \
  X(base##2I), \
  X(base##3I)
#else
#define INST_HELPER_ARG(base, X) \
  X(base##RR), \
  X(base##0R), \
  X(base##1R), \
  X(base##2R), \
  X(base##3R), \
  X(base##4R), \
  X(base##5R), \
  X(base##R0), \
  X(base##00), \
  X(base##10), \
  X(base##20), \
  X(base##30), \
  X(base##40), \
  X(base##50), \
  X(base##R1), \
  X(base##01), \
  X(base##11), \
  X(base##21), \
  X(base##31), \
  X(base##41), \
  X(base##51), \
  X(base##R2), \
  X(base##02), \
  X(base##12), \
  X(base##22), \
  X(base##32), \
  X(base##42), \
  X(base##52), \
  X(base##RI), \
  X(base##0I), \
  X(base##1I), \
  X(base##2I), \
  X(base##3I), \
  X(base##4I), \
  X(base##5I)

#define INST_HELPER_ARG_REAL(base, X) \
  X(base##RR), \
  X(base##0R), \
  X(base##1R), \
  X(base##2R), \
  X(base##3R), \
  X(base##4R), \
  X(base##5R), \
  X(base##6R), \
  X(base##7R), \
  X(base##R0), \
  X(base##00), \
  X(base##10), \
  X(base##20), \
  X(base##30), \
  X(base##40), \
  X(base##50), \
  X(base##60), \
  X(base##70), \
  X(base##R1), \
  X(base##01), \
  X(base##11), \
  X(base##21), \
  X(base##31), \
  X(base##41), \
  X(base##51), \
  X(base##61), \
  X(base##71), \
  X(base##R2), \
  X(base##02), \
  X(base##12), \
  X(base##22), \
  X(base##32), \
  X(base##42), \
  X(base##52), \
  X(base##62), \
  X(base##72), \
  X(base##RI), \
  X(base##0I), \
  X(base##1I), \
  X(base##2I), \
  X(base##3I), \
  X(base##4I), \
  X(base##5I), \
  X(base##6I), \
  X(base##7I)
#endif

#define INST_HELPER_COND(base, X) \
  X(base##EQ), \
  X(base##NE), \
  X(base##GT), \
  X(base##LT), \
  X(base##GE), \
  X(base##LE)

#define I(x) instruction_address[(x)]
enum {
  I_RESERVE_STACK = 0,
  INST_HELPER_2(I_MOVE, ID),
  INST_HELPER_1(I_MOVE, I, ID),
  INST_HELPER_1(I_MOVE, GLOBAL, ID),
  INST_HELPER_1(I_MOVEGLOBAL, , ID),
  I_MOVEGLOBALFUNI,
  INST_HELPER_2(I_ADD, ID),
  INST_HELPER_1(I_ADD, I, ID),
  INST_HELPER_1(I_ADD, IF, ID),
  INST_HELPER_2(I_SUB, ID),
  INST_HELPER_2(I_MUL, ID),
  INST_HELPER_1(I_MUL, I, ID),
  INST_HELPER_1(I_MUL, IF, ID),
  INST_HELPER_2(I_DIV, ID),
  INST_HELPER_1(I_NEGATE, , ID),
  I_JMP,
  INST_HELPER_2(I_CMP, ID),
  INST_HELPER_1(I_CMP, I, ID),
  INST_HELPER_2(I_INC_JMP_LT, ID),
  INST_HELPER_COND(I_JMP_, ID),
  INST_HELPER_1(I_RETC, , ID),
  INST_HELPER_1(I_RET, , ID),
  I_CALL,
  I_CALLINTN,
  INST_HELPER_1(I_CALLINT, , ID),
  I_CALLEXTN,
  INST_HELPER_1(I_CALLEXT, , ID),
  INST_HELPER_1(I_MOVERETVAL, , ID),
  INST_HELPER_1(I_INCREF, , ID),
  INST_HELPER_1(I_DECREF, , ID),
  INST_HELPER_2(I_AINDEX, ID),
  INST_HELPER_1(I_AINDEX, I, ID),
  INST_HELPER_2(I_SAINDEX, ID),
  INST_HELPER_1(I_SAVALUE, , ID),
  I_READ_OBJ,
  I_READ_I1,
  I_READ_U1,
  I_READ_I2,
  I_READ_U2,
  I_READ_I4,
  I_READ_U4,
  I_READ_I8,
  I_READ_U8,
  I_READ_F4,
  I_READ_F8,
  I_STORE_OBJ,
  I_STORE_I1,
  I_STORE_U1,
  I_STORE_I2,
  I_STORE_U2,
  I_STORE_I4,
  I_STORE_U4,
  I_STORE_I8,
  I_STORE_U8,
  I_STORE_F4,
  I_STORE_F8,
  INST_HELPER_ARG(I_ULONGARG, ID),
  INST_HELPER_ARG(I_PTRARG, ID),
  INST_HELPER_ARG_REAL(I_F8ARG, ID),
  INST_HELPER_ARG_REAL(I_F4ARG, ID),
  I_CALLEXT2N,
  INST_HELPER_1(I_CALLEXT2, , ID),
  I_CALLEXT2_PREPARE,
  I_DEBUG_BREAK,
};

enum {
  C_MIN = 1,
  C_EQ = 1,
  C_NE,
  C_GT,
  C_LT,
  C_GE,
  C_LE,
  C_MAX
};

i8 condition_negation[] = {
  [C_EQ] = C_NE,
  [C_NE] = C_EQ,
  [C_GT] = C_LE,
  [C_LT] = C_GE,
  [C_GE] = C_LT,
  [C_LE] = C_GT
};

i8 condition_swap_args[] = {
  [C_EQ] = C_EQ,
  [C_NE] = C_NE,
  [C_GT] = C_LE,
  [C_LT] = C_GE,
  [C_GE] = C_LT,
  [C_LE] = C_GT
};

#define DEF_STRING(x) [(x)] = #x
const i1 *bytecode_names[] = {
  DEF_STRING(I_RESERVE_STACK),
  INST_HELPER_2(I_MOVE, DEF_STRING),
  INST_HELPER_1(I_MOVE, I, DEF_STRING),
  INST_HELPER_1(I_MOVE, GLOBAL, DEF_STRING),
  INST_HELPER_1(I_MOVEGLOBAL, , DEF_STRING),
  DEF_STRING(I_MOVEGLOBALFUNI),
  INST_HELPER_2(I_ADD, DEF_STRING),
  INST_HELPER_1(I_ADD, I, DEF_STRING),
  INST_HELPER_1(I_ADD, IF, DEF_STRING),
  INST_HELPER_2(I_SUB, DEF_STRING),
  INST_HELPER_2(I_MUL, DEF_STRING),
  INST_HELPER_1(I_MUL, I, DEF_STRING),
  INST_HELPER_1(I_MUL, IF, DEF_STRING),
  INST_HELPER_2(I_DIV, DEF_STRING),
  INST_HELPER_1(I_NEGATE, , DEF_STRING),
  DEF_STRING(I_JMP),
  INST_HELPER_2(I_CMP, DEF_STRING),
  INST_HELPER_1(I_CMP, I, DEF_STRING),
  INST_HELPER_2(I_INC_JMP_LT, DEF_STRING),
  INST_HELPER_COND(I_JMP_, DEF_STRING),
  INST_HELPER_1(I_RETC, , DEF_STRING),
  INST_HELPER_1(I_RET, , DEF_STRING),
  DEF_STRING(I_CALL),
  DEF_STRING(I_CALLINTN),
  INST_HELPER_1(I_CALLINT, , DEF_STRING),
  DEF_STRING(I_CALLEXTN),
  INST_HELPER_1(I_CALLEXT, , DEF_STRING),
  INST_HELPER_1(I_MOVERETVAL, , DEF_STRING),
  INST_HELPER_1(I_INCREF, , DEF_STRING),
  INST_HELPER_1(I_DECREF, , DEF_STRING),
  INST_HELPER_2(I_AINDEX, DEF_STRING),
  INST_HELPER_1(I_AINDEX, I, DEF_STRING),
  INST_HELPER_2(I_SAINDEX, DEF_STRING),
  INST_HELPER_1(I_SAVALUE, , DEF_STRING),
  DEF_STRING(I_READ_I1),
  DEF_STRING(I_READ_U1),
  DEF_STRING(I_READ_I2),
  DEF_STRING(I_READ_U2),
  DEF_STRING(I_READ_I4),
  DEF_STRING(I_READ_U4),
  DEF_STRING(I_READ_I8),
  DEF_STRING(I_READ_U8),
  DEF_STRING(I_READ_F4),
  DEF_STRING(I_READ_F8),
  DEF_STRING(I_STORE_I1),
  DEF_STRING(I_STORE_U1),
  DEF_STRING(I_STORE_I2),
  DEF_STRING(I_STORE_U2),
  DEF_STRING(I_STORE_I4),
  DEF_STRING(I_STORE_U4),
  DEF_STRING(I_STORE_I8),
  DEF_STRING(I_STORE_U8),
  DEF_STRING(I_STORE_F4),
  DEF_STRING(I_STORE_F8),
  INST_HELPER_ARG(I_ULONGARG, DEF_STRING),
  INST_HELPER_ARG(I_PTRARG, DEF_STRING),
  INST_HELPER_ARG_REAL(I_F8ARG, DEF_STRING),
  INST_HELPER_ARG_REAL(I_F4ARG, DEF_STRING),
  DEF_STRING(I_CALLEXT2N),
  INST_HELPER_1(I_CALLEXT2, , DEF_STRING),
  DEF_STRING(I_CALLEXT2_PREPARE),
  DEF_STRING(I_DEBUG_BREAK),
};

/*
 * Variables
 */

typedef struct {
  //globals_t globals;

  i8 print_times;

  i8 symbol_count;
  // TODO hashmap
  i1 symbols[MAX_SYMBOLS][1024];
  obj symbol_object[MAX_SYMBOLS];

  i1 file_sarch_path[100][1024];
  i8 file_search_path_count;

  /* predefined symbols */
  obj s_comment;
  obj s_quote;
  obj s_define;
  obj s_debug_break;
  obj s_plus;
  obj s_times;
  obj s_minus;
  obj s_divide;
  obj s_negate;
  obj s_if;
  obj s_for;
  obj s_let;
  obj s_aindex;
  obj s_aindexi;
  obj s_aindexr;
  obj s_saindexr;
  obj s_do;
  obj s_set;
  obj s_inc;
  obj s_with_loop;
  obj s_continue;
  obj s_next_loop;
  obj s_eq;
  obj s_ne;
  obj s_gt;
  obj s_lt;
  obj s_ge;
  obj s_le;
  obj s_label;
  obj s_float;
  obj s_double;
  obj s_char;
  obj s_uchar;
  obj s_int;
  obj s_uint;
  obj s_long;
  obj s_ulong;
  obj s_ptr;
  obj s_void;
  obj s_define_c;
  /* symbols that pertain to bytecode operations */
  obj s_moverr;
  obj s_moveri; // move immediate value into a register and increment refcount
  obj s_moverglobal; // moves value of a global variable to a register and increments refcount
  obj s_moveglobalr; // moves register into a global variable (previous value is decref'd) without increfing
  obj s_moveglobalfuni; // moves immediate value into function value of a global variable (previous value is decref'd) without increfing
  obj s_addrr;
  obj s_addri;
  obj s_subrr;
  obj s_mulrr;
  obj s_mulri;
  obj s_divrr;
  obj s_cmprr;
  obj s_cmpri;
  obj s_jump;
  obj s_inc_jump_lt;
  obj s_jump_eq;
  obj s_jump_ne;
  obj s_jump_gt;
  obj s_jump_lt;
  obj s_jump_ge;
  obj s_jump_le;
  obj s_retc;
  obj s_ret;
  obj s_call;
  obj s_call_internal;
  obj s_call_external;
  obj s_incref;
  obj s_decref;
  obj s_ulongarg;
  obj s_ulongargi;
  obj s_ptrarg;
  obj s_ptrargi;
  obj s_f4arg;
  obj s_f4argi;
  obj s_f8arg;
  obj s_f8argi;
  obj s_call_external2;
  obj s_call_external2_prepare;
} interpreter_t;

interpreter_t global_instance;

u0 init_addresses(u0);
u0 init_interpreter(interpreter_t *interp);

i8 repl(interpreter_t *interp, const i1 *filename);

struct {
  i8 sym_offset;
  const i1 *str;
} initializations[] = {
  { offsetof(interpreter_t, s_comment), "comment" },
  { offsetof(interpreter_t, s_quote), "quote" },
  { offsetof(interpreter_t, s_define), "define" },
  { offsetof(interpreter_t, s_debug_break), "debug-break" },
  { offsetof(interpreter_t, s_plus), "+" },
  { offsetof(interpreter_t, s_times), "*" },
  { offsetof(interpreter_t, s_minus), "-" },
  { offsetof(interpreter_t, s_divide), "/" },
  { offsetof(interpreter_t, s_negate), "negate" },
  { offsetof(interpreter_t, s_if), "if" },
  { offsetof(interpreter_t, s_for), "for" },
  { offsetof(interpreter_t, s_let), "let" },
  { offsetof(interpreter_t, s_aindex), "aindex" },
  { offsetof(interpreter_t, s_aindexi), "aindexi" },
  { offsetof(interpreter_t, s_aindexr), "aindexr" },
  { offsetof(interpreter_t, s_saindexr), "saindexr" },
  { offsetof(interpreter_t, s_do), "do" },
  { offsetof(interpreter_t, s_set), "set" },
  { offsetof(interpreter_t, s_inc), "++" },
  { offsetof(interpreter_t, s_with_loop), "with-loop" },
  { offsetof(interpreter_t, s_continue), "continue" },
  { offsetof(interpreter_t, s_next_loop), "next-loop" },
  { offsetof(interpreter_t, s_eq), "==" },
  { offsetof(interpreter_t, s_ne), "!=" },
  { offsetof(interpreter_t, s_gt), ">" },
  { offsetof(interpreter_t, s_lt), "<" },
  { offsetof(interpreter_t, s_ge), ">=" },
  { offsetof(interpreter_t, s_le), "<=" },
  { offsetof(interpreter_t, s_label), "label" },
  { offsetof(interpreter_t, s_float), "float" },
  { offsetof(interpreter_t, s_double), "double" },
  { offsetof(interpreter_t, s_char), "char" },
  { offsetof(interpreter_t, s_uchar), "uchar" },
  { offsetof(interpreter_t, s_int), "int" },
  { offsetof(interpreter_t, s_uint), "uint" },
  { offsetof(interpreter_t, s_long), "long" },
  { offsetof(interpreter_t, s_ulong), "ulong" },
  { offsetof(interpreter_t, s_ptr), "ptr" },
  { offsetof(interpreter_t, s_void), "void" },
  { offsetof(interpreter_t, s_define_c), "define-c" },
  /* symbols that pertain to bytecode operations */
  { offsetof(interpreter_t, s_moverr), "moverr" },
  { offsetof(interpreter_t, s_moveri), "moveri" },
  { offsetof(interpreter_t, s_moverglobal), "moverglobal" },
  { offsetof(interpreter_t, s_moveglobalr), "moveglobalr" },
  { offsetof(interpreter_t, s_moveglobalfuni), "moveglobalfuni" },
  { offsetof(interpreter_t, s_addrr), "addrr" },
  { offsetof(interpreter_t, s_addri), "addri" },
  { offsetof(interpreter_t, s_subrr), "subrr" },
  { offsetof(interpreter_t, s_mulrr), "mulrr" },
  { offsetof(interpreter_t, s_mulri), "mulri" },
  { offsetof(interpreter_t, s_divrr), "divrr" },
  { offsetof(interpreter_t, s_cmprr), "cmprr" },
  { offsetof(interpreter_t, s_cmpri), "cmpri" },
  { offsetof(interpreter_t, s_jump), "jump" },
  { offsetof(interpreter_t, s_inc_jump_lt), "inc_jump_lt" },
  { offsetof(interpreter_t, s_jump_eq), "jump_eq" },
  { offsetof(interpreter_t, s_jump_ne), "jump_ne" },
  { offsetof(interpreter_t, s_jump_gt), "jump_gt" },
  { offsetof(interpreter_t, s_jump_lt), "jump_lt" },
  { offsetof(interpreter_t, s_jump_ge), "jump_ge" },
  { offsetof(interpreter_t, s_jump_le), "jump_le" },
  { offsetof(interpreter_t, s_retc), "retc" },
  { offsetof(interpreter_t, s_ret), "ret" },
  { offsetof(interpreter_t, s_call), "call" },
  { offsetof(interpreter_t, s_call_internal), "call_internal" },
  { offsetof(interpreter_t, s_call_external), "call_external" },
  { offsetof(interpreter_t, s_incref), "incref" },
  { offsetof(interpreter_t, s_decref), "decref" },
  { offsetof(interpreter_t, s_ulongarg), "ulongarg" },
  { offsetof(interpreter_t, s_ulongargi), "ulongargi" },
  { offsetof(interpreter_t, s_ptrarg), "ptrarg" },
  { offsetof(interpreter_t, s_ptrargi), "ptrargi" },
  { offsetof(interpreter_t, s_f4arg), "f4arg" },
  { offsetof(interpreter_t, s_f4argi), "f4argi" },
  { offsetof(interpreter_t, s_f8arg), "f8arg" },
  { offsetof(interpreter_t, s_f8argi), "f8argi" },
  { offsetof(interpreter_t, s_call_external2), "call_external2" },
  { offsetof(interpreter_t, s_call_external2_prepare), "call_external2_prepare" },
};

i8 conditional_jump_sym[] = {
  [C_EQ] = offsetof(interpreter_t, s_jump_eq),
  [C_NE] = offsetof(interpreter_t, s_jump_ne),
  [C_GT] = offsetof(interpreter_t, s_jump_gt),
  [C_LT] = offsetof(interpreter_t, s_jump_lt),
  [C_GE] = offsetof(interpreter_t, s_jump_ge),
  [C_LE] = offsetof(interpreter_t, s_jump_le),
};

#define SYMBOL_OBJ(interp, offset) *(obj *)((u1 *)(interp) + (offset))

/* extern from assembly */
extern const u8 instruction_offset[1];
extern const i8 instruction_count;
extern u8 vm_execute(u8 *code, u8 *registers, u0 *interp);
u8 instruction_address[1024];

/*
 * Function declarations
 */

u0 free_object(interpreter_t *interp, obj o);
u0 print_object(io_stream_t f, obj o);

FORCE_INLINE obj inc_ref(interpreter_t *interp, obj o)
{
  if (IS_REF_COUNTED(o))
  {
#ifdef DEBUG_REFCOUNT
    FMT(STDOUT_H, "Incref 0x%llx %llu ", (u8)o, GET_POINTER(o)->ref_count + 1);
    print_object(STDOUT_H, o);
    FMT(STDOUT_H, "\n");
#endif

    ATOMIC_ADD_AND_FETCH64(&GET_POINTER(o)->ref_count, 1);
  }
  return o;
}

FORCE_INLINE u0 dec_ref(interpreter_t *interp, obj o)
{
  if (IS_REF_COUNTED(o))
  {
#ifdef DEBUG_REFCOUNT
    {
      FMT(STDOUT_H, "Decref 0x%llx %llu ", (u8)o, GET_POINTER(o)->ref_count - 1);
      print_object(STDOUT_H, o);
      FMT(STDOUT_H, "\n");

      if (GET_POINTER(o)->ref_count == 0)
        BP();
    }
#endif

    if (ATOMIC_ADD_AND_FETCH64(&GET_POINTER(o)->ref_count, -1) == 0)
      free_object((interp), (o));
  }
}

/*
 * Implementations
 */

u8 f8_to_u8_binary(f8 x)
{
  union { f8 x; u8 i; } a;
  a.x = x;
  return a.i;
}

f8 u8_to_f8_binary(u8 i)
{
  union { f8 x; u8 i; } a;
  a.i = i;
  return a.x;
}

typedef struct type_description_t {
  i8 et;
  i8 element_size;
  u8 read_bytecode;
  u8 store_bytecode;
  const i1 *printable_name;
} type_description_t;

enum {
  ET_ANY = 0,
  ET_I1 = 1,
  ET_U1 = 2,
  ET_I2 = 3,
  ET_U2 = 4,
  ET_I4 = 5,
  ET_U4 = 6,
  ET_I8 = 7,
  ET_U8 = 8,
  ET_F4 = 9,
  ET_F8 = 10,
  ET_STRING = 11,
};

type_description_t basic_types[] = {
  { ET_ANY, 8, I_READ_OBJ, I_STORE_OBJ, "any" },
  { ET_I1, 1, I_READ_I1, I_STORE_I1, "i1" },
  { ET_U1, 1, I_READ_U1, I_STORE_U1, "u1" },
  { ET_I2, 2, I_READ_I2, I_STORE_I2, "i2" },
  { ET_U2, 2, I_READ_U2, I_STORE_U2, "u2" },
  { ET_I4, 4, I_READ_I4, I_STORE_I4, "i4" },
  { ET_U4, 4, I_READ_U4, I_STORE_U4, "u4" },
  { ET_I8, 8, I_READ_I8, I_STORE_I8, "i8" },
  { ET_U8, 8, I_READ_U8, I_STORE_U8, "u8" },
  { ET_F4, 4, I_READ_F4, I_STORE_F4, "f4" },
  { ET_F8, 8, I_READ_F8, I_STORE_F8, "f8" },
  { ET_STRING, 1, I_READ_U1, I_STORE_U1, "string_u1" },
};

obj alloc_array(interpreter_t *interp, i8 size, u8 element_type)
{
  if (size < 0)
    size = 0;

  array_t *l = MALLOC_TYPE(array_t);
  l->header.ref_count = 1;
  l->header.type = TYPE_ARRAY;
  l->size = size;
  l->storage_size = size;
  l->element_type = element_type;
  l->read_bytecode = I(I_READ_I1);
  l->store_bytecode = I(I_STORE_I1);
  l->element_size = 1;

  if (element_type < ARRAY_SIZE(basic_types))
  {
    l->read_bytecode = I(basic_types[element_type].read_bytecode);
    l->store_bytecode = I(basic_types[element_type].store_bytecode);
    l->element_size = basic_types[element_type].element_size;
  }

  if (size > 0)
  {
    l->storage = (u0 *)MALLOC_ARRAY(u1, l->element_size * l->storage_size);
    if (l->storage)
    {
      if (l->element_type == ET_ANY)
      {
        for (i8 i = 0; i < l->size; i++)
        ((obj *)l->storage)[i] = NONE_VALUE;
      }
      else
      {
        memory_set(l->storage, 0, l->element_size * l->storage_size);
      }
    }
    else
    {
      free(l);
      PRINT_ERROR("Allocation of array failed!\n");
      return NONE_VALUE;
    }
  }
  else
  {
    l->storage = NULL;
  }

  return MAKE_ALLOCATED(l);
}

obj make_array(interpreter_t *interp, i8 size, ...)
{
  obj o_ret = alloc_array(interp, size, ET_ANY);

  va_list args;
  va_start(args, size);
  for (i8 i = 0; i < size; i++)
  {
    obj o1 = va_arg(args, u8);
    NTH(o_ret, i) = o1;
  }

  va_end(args);

  return o_ret;
}

u0 array_free_storage(interpreter_t *interp, obj o)
{
  if (IS_OBJ_ARRAY(o))
  {
    for (i8 i = 0; i < ASIZE(o); i++)
      DEC(interp, NTH(o, i));
  }
  array_t *l = GET_ARR(o);
  free(l->storage);
  l->storage_size = 0;
  l->size = 0;
  l->storage = NULL;
}

u0 array_resize_storage(obj o, i8 new_size)
{
  array_t *l = GET_ARR(o);
  if (new_size > l->storage_size)
  {
    obj *s1 = (obj *)l->storage;
    i8 bytes = l->element_size * new_size;
    l->storage = (u0 *)MALLOC_ARRAY(u1, bytes);
    if (s1 && l->size > 0)
      memory_copy(l->storage, s1, l->element_size * l->size);
    l->storage_size = new_size;
    if (l->element_type == ET_STRING && l->storage_size > 0)
    {
      ((u1*)l->storage)[l->size] = '\0';
    }
    if (s1)
      free(s1);
  }
}

i8 get_as_i8(obj o, i8 default_value)
{
  if (IS_INTEGER(o)) return GET_INTEGER(o);
  else if (IS_REAL(o)) return (i8)TO_F8(o);
  return default_value;
}

f8 get_as_f8(obj o, f8 default_value)
{
  if (IS_INTEGER(o)) return (f8)GET_INTEGER(o);
  else if (IS_REAL(o)) return TO_F8(o);
  return default_value;
}

obj get_array_element(interpreter_t *interp, array_t* arr, i8 idx, i1 incref_obj)
{
  u1* storage = &((u1*)arr->storage)[idx * arr->element_size];

  switch (arr->element_type)
  {
  case ET_ANY:
    {
      obj o = *(obj*)storage;
      return incref_obj ? INC(interp, o) : o;
    }
  case ET_I1:
    return MAKE_INTEGER(*(i1*)storage);
  case ET_U1:
  case ET_STRING:
    return MAKE_INTEGER(*(u1*)storage);
  case ET_I2:
    return MAKE_INTEGER(*(i2*)storage);
  case ET_U2:
    return MAKE_INTEGER(*(u2*)storage);
  case ET_I4:
    return MAKE_INTEGER(*(i4*)storage);
  case ET_U4:
    return MAKE_INTEGER(*(u4*)storage);
  case ET_I8:
    return MAKE_INTEGER(*(i8*)storage);
  case ET_U8:
    return MAKE_INTEGER(*(u8*)storage);
  case ET_F4:
    return MAKE_REAL(*(f4*)storage);
  case ET_F8:
    return MAKE_REAL(*(f8*)storage);
  }

  return NONE_VALUE;
}

u0 set_array_element(interpreter_t *interp, array_t* arr, i8 idx, obj o, i1 incref_obj)
{
  u1* storage = &((u1*)arr->storage)[idx * arr->element_size];

  switch (arr->element_type)
  {
  case ET_ANY:
    *(obj*)storage = incref_obj ? INC(interp, o) : o;
    break;
  case ET_I1:
    *(i1*)storage = get_as_i8(o, 0);
    break;
  case ET_U1:
  case ET_STRING:
    *(u1*)storage = get_as_i8(o, 0);
    break;
  case ET_I2:
    *(i2*)storage = get_as_i8(o, 0);
    break;
  case ET_U2:
    *(u2*)storage = get_as_i8(o, 0);
    break;
  case ET_I4:
    *(i4*)storage = get_as_i8(o, 0);
    break;
  case ET_U4:
    *(u4*)storage = get_as_i8(o, 0);
    break;
  case ET_I8:
    *(i8*)storage = get_as_i8(o, 0);
    break;
  case ET_U8:
    *(u8*)storage = get_as_i8(o, 0);
    break;
  case ET_F4:
    *(f4*)storage = get_as_f8(o, 0.0);
    break;
  case ET_F8:
    *(f8*)storage = get_as_f8(o, 0.0);
    break;
  }
}

u0 zero_terminate_string(array_t* arr)
{
  if (arr->element_type == ET_STRING)
    ((u1*)arr->storage)[arr->size] = '\0'; // null terminate it
}

u0 ensure_array_storage(obj o, i8 requested_size)
{
  array_t *arr = GET_ARR(o);

  requested_size += (arr->element_type == ET_STRING ? 1 : 0);

  if (arr->storage_size < requested_size)
  {
    i8 new_size = MAX_MACRO(arr->storage_size > 0 ? arr->storage_size * 2 : 1, requested_size);
    array_resize_storage(o, new_size);
  }
}

obj array_remove_obj(interpreter_t *interp, obj o1, i8 pos)
{
  array_t *arr = GET_ARR(o1);

  if (pos >= 0 && pos < arr->size)
  {
    obj ret = get_array_element(interp, arr, pos, 0);

    memory_copy(&GET_ARRAY_STORAGE(u1, o1)[pos * arr->element_size],
      &GET_ARRAY_STORAGE(u1, o1)[(pos + 1) * arr->element_size],
      (arr->size - (pos + 1)) * arr->element_size);

    arr->size--;
    zero_terminate_string(arr);

    return ret;
  }

  return NONE_VALUE;
}

u0 array_insert_obj(interpreter_t *interp, obj o1, obj o, i8 pos)
{
  array_t *arr = GET_ARR(o1);

  ensure_array_storage(o1, arr->size + 1);

  // make a space at index pos
  if (pos != arr->size)
  {
    memory_copy(&GET_ARRAY_STORAGE(u1, o1)[(pos + 1) * arr->element_size],
      &GET_ARRAY_STORAGE(u1, o1)[pos * arr->element_size],
      (arr->size - pos) * arr->element_size);
  }
  set_array_element(interp, arr, pos, o, 0);

  arr->size++;
  zero_terminate_string(arr);
}

u0 array_add_obj(interpreter_t *interp, obj o1, obj o)
{
  array_insert_obj(interp, o1, o, ASIZE(o1));
}

obj array_copy(interpreter_t *interp, obj o1, i8 offset)
{
  i8 size = ASIZE(o1) - offset;
  array_t *l1 = GET_ARR(o1);
  if (size > 0)
  {
    obj o_ret = alloc_array(interp, size, l1->element_type);
    array_t *l2 = GET_ARR(o_ret);

    if (l1->element_type == ET_ANY)
    {
      for (i8 i = offset; i < ASIZE(o1); i++)
      {
        obj tmp = NTH(o1, i);
        INC(interp, tmp);
        ((obj *)l2->storage)[i - offset] = tmp;
      }
    }
    else
    {
      i8 bytes = size * l1->element_size;
      memory_copy(l2->storage, &((u1 *)l1->storage)[offset], bytes);
    }

    return o_ret;
  }
  else
  {
    return alloc_array(interp, 0, l1->element_type);
  }
}

u0 array_append(interpreter_t *interp, obj o1, obj o2, i1 move_objects)
{
  array_t *l = GET_ARR(o1);
  array_t *l2 = GET_ARR(o2);

  if (l->element_size != l2->element_size)
  {
    BP();
    return;
  }

  ensure_array_storage(o1, ASIZE(o1) + ASIZE(o2));

  memory_copy(&((u1 *)l->storage)[l->size * l->element_size],
      l2->storage,
      l2->size * l2->element_size);

  l->size += l2->size;

  zero_terminate_string(l);

  if (move_objects)
  {
    l2->size = 0;
  }
  else
  {
    if (l->element_type == ET_ANY && l2->element_type == ET_ANY)
    {
      for (i8 i = 0; i < l2->size; i++)
      {
        INC(interp, NTH(o2, i));
      }
    }
  }
}

u0 array_move(interpreter_t *interp, obj o1, obj o2)
{
  array_t *l1 = GET_ARR(o1);
  array_t *l2 = GET_ARR(o2);

  array_free_storage(interp, o1);

  l1->storage = l2->storage;
  l1->size = l2->size;
  l1->storage_size = l2->storage_size;


  l2->storage = NULL;
  l2->size = 0;
  l2->storage_size = 0;
}

obj make_string(interpreter_t *interp, const i1 *value, i8 len, i1 copy)
{
  // FMT(STDOUT_H, "New string: %s\n", value);
  i8 string_length = len >= 0 ? len : str_length(value);

  obj o_ret = alloc_array(interp, copy ? (string_length + 1) : 0, ET_STRING);

  if (copy)
  {
    if (string_length > 0)
      memory_copy(GET_STRING_STORAGE(o_ret), value, string_length);
    NTH_TYPE(i1, o_ret, string_length) = '\0';
    array_t *l = GET_ARR(o_ret);
    l->size = string_length;
  }
  else
  {
    array_t *l = GET_ARR(o_ret);
    l->storage = (u0 *)value;
    l->size = string_length;
    l->storage_size = string_length + 1;
  }

  return o_ret;
}

obj make_symbol(interpreter_t *interp, const i1 *name)
{
  if (str_compare(name, "None") == 0)
    return NONE_VALUE;

  if (str_compare(name, "nil") == 0) // TEMPORARY
    return NONE_VALUE;

  for (i8 i = 0; i < interp->symbol_count; i++)
  {
    if (str_compare(interp->symbols[i], name) == 0)
    {
      INC(interp, interp->symbol_object[i]);
      return interp->symbol_object[i];
    }
  }

  // FMT(STDOUT_H, "New symbol %lld: %s\n", interp->symbol_count, name);
  str_copy(interp->symbols[interp->symbol_count], name);
  symbol_t *sym = MALLOC_TYPE(symbol_t);
  sym->header.ref_count = 2;
  sym->header.type = TYPE_SYMBOL;
  sym->flags = 0;
  sym->value = NONE_VALUE;
  sym->function_value = NONE_VALUE;
  sym->name = str_duplicate(interp->symbols[interp->symbol_count]);

  interp->symbol_object[interp->symbol_count] = MAKE_SYMBOL(sym);
  interp->symbol_count++;
  return interp->symbol_object[interp->symbol_count - 1];
}

const i1 *get_symbol_string(obj o)
{
  return GET_SYMBOL(o)->name;
}

#if 0
obj get_symbol_value(obj o)
{
  return GET_SYMBOL(o)->value;
}

u0 set_symbol_value(obj o, obj val)
{
  GET_SYMBOL(o)->value = val;
  GET_SYMBOL(o)->flags |= SF_HAS_VALUE;
}
#endif

u0 set_symbol_function_value(obj o, obj val)
{
  GET_SYMBOL(o)->function_value = val;
  GET_SYMBOL(o)->flags |= SF_HAS_FUNCTION_VALUE;
}

obj make_function(u8 function_type, u0 *ptr, i8 min_arg_count, i8 max_arg_count, obj immediates)
{
  function_t *l = MALLOC_TYPE(function_t);
  if ((u8)l & 0x3) FMT(STDOUT_H, "malloc not aligned: 0x%llx\n", (u8)l);
  l->header.ref_count = 1;
  l->header.type = TYPE_FUNCTION;
  l->ptr = ptr;
  l->function_type = function_type;
  l->min_arg_count = min_arg_count;
  l->max_arg_count = max_arg_count;
  l->immediates = immediates;
  l->arg_types = NONE_VALUE;
  l->code = NONE_VALUE;
  l->ir_code = NONE_VALUE;

  return MAKE_ALLOCATED(l);
}

typedef struct parse_state
{
  const i1 *begin;
  const i1 *end;
  const i1 *pos;
  i8 state;
  i1 str[1024];
  i8 str_pos;
  i8 stack_pos;
  obj stack[128];
  i8 stack_expr_parse_type[128];
  i1 *error_txt;
} parse_state;

i1 whitespace(i1 c)
{
  return (c == ' ' || c == '\r' || c == '\n' || c == '\t') ? 1 : 0;
}

enum {
  STATE_ERROR = -1,
  STATE_NEXT_TOKEN = 0,
  STATE_SLASH_CHARACTER,
  STATE_PLUS_CHARACTER,
  STATE_MINUS_CHARACTER,
  STATE_READ_INTEGER,
  STATE_READ_REAL,
  STATE_READ_SYMBOL,
  STATE_READ_STRING,
  STATE_READ_STRING_ESCAPED,
  STATE_READ_COMMENT_LINE,
  STATE_READ_COMMENT_C,
  STATE_READ_COMMENT_C_STAR,
};

enum {
  EXPR_NORMAL = 1,
  EXPR_INDEX = 2,
};

#define PARSE_ERROR(str) do { state->error_txt = str_duplicate(str); state->state = STATE_ERROR; return; } while (0)

u0 parse_character(i1 c, interpreter_t *interp, parse_state *state)
{
  obj obj_to_add = NONE_VALUE;
reprocess_char:
  // FMT(STDOUT_H, "parse state %lld %c\n", state->state, c);
  switch (state->state)
  {
    case STATE_NEXT_TOKEN:
      {
        switch (c)
        {
          case '(':
            state->pos++;
            obj o = make_array(interp, 0);
            array_add_obj(interp, state->stack[state->stack_pos], o);
            state->stack_pos++;
            state->stack[state->stack_pos] = o;
            state->stack_expr_parse_type[state->stack_pos] = EXPR_NORMAL; /* normal expression */
            break;
          case ')':
            if (state->stack_expr_parse_type[state->stack_pos] != EXPR_NORMAL)
            {
              PARSE_ERROR("Non matching closing parenthesis");
            }
            state->pos++;
            if (state->stack_pos == 0)
            {
              PARSE_ERROR("Too many closing parenthesis");
            }
            state->stack_pos--;
            break;
          case ']':
            if (state->stack_expr_parse_type[state->stack_pos] != EXPR_INDEX)
            {
              PARSE_ERROR("Non matching closing bracket");
            }
            state->pos++;
            if (state->stack_pos == 0)
            {
              PARSE_ERROR("Too many closing brackets");
            }
            state->stack_pos--;
            break;
          case '"':
            state->state = STATE_READ_STRING;
            state->pos++;
            state->str_pos = 0;
            break;
          case ';':
            state->state = STATE_READ_COMMENT_LINE;
            state->pos++;
            break;
          case '/':
            state->state = STATE_SLASH_CHARACTER;
            state->pos++;
            break;
          case '+':
            state->state = STATE_PLUS_CHARACTER;
            state->pos++;
            break;
          case '-':
            state->state = STATE_MINUS_CHARACTER;
            state->pos++;
            break;
          default:
            if (c >= '0' && c <= '9')
            {
              state->state = STATE_READ_INTEGER;
              state->str_pos = 0;
            }
            else
            {
              state->state = STATE_READ_SYMBOL;
              state->str_pos = 0;
            }
            break;
        }
      }
      break;
    case STATE_PLUS_CHARACTER:
    case STATE_MINUS_CHARACTER:
      if ((c >= '0' && c <= '9'))
      {
        state->str_pos = 0;
        if (state->state == STATE_MINUS_CHARACTER)
        {
          state->str[0] = '-';
          state->str_pos = 1;
        }
        /* don't 'eat' the current character */
        state->state = STATE_READ_INTEGER;
        goto reprocess_char;
      }
      else
      {
        state->str[0] = state->state == STATE_PLUS_CHARACTER ? '+' : '-';
        state->str_pos = 1;
        /* don't 'eat' the current character */
        state->state = STATE_READ_SYMBOL;
        goto reprocess_char;
      }
      break;
    case STATE_SLASH_CHARACTER:
      if (c == '/')
      {
        state->state = STATE_READ_COMMENT_LINE;
        state->pos++;
      }
      else if (c == '*')
      {
        state->state = STATE_READ_COMMENT_C;
        state->pos++;
      }
      else
      {
        state->state = STATE_READ_SYMBOL;
        state->str[0] = '/';
        state->str_pos = 1;
        /* don't 'eat' the current character */
        goto reprocess_char;
      }
      break;
    case STATE_READ_INTEGER:
      {
        if (whitespace(c) || c == '(' || c == ')' || c == ']')
        {
          state->str[state->str_pos] = '\0';
          i8 n;
          if (state->str[0] == '0' && (state->str[1] == 'x' || state->str[1] == 'X'))
            n = strtoll(state->str + 2, NULL, 16);
          else
            n = strtoll(state->str, NULL, 10);
          obj_to_add = MAKE_INTEGER(n);
          state->state = STATE_NEXT_TOKEN;
          goto add_object;
        }
        else if ((c == 'e' || c == 'E') && (state->str_pos > 1 && state->str[0] == '0' && (state->str[1] == 'x' || state->str[1] == 'X')))
        {
          state->str[state->str_pos++] = c;
          state->pos++;
        }
        else if (c == '.' || c == 'e' || c == 'E')
        {
          state->state = STATE_READ_REAL;
          goto reprocess_char;
        }
        else
        {
          state->str[state->str_pos++] = c;
          state->pos++;
        }
      }
      break;
    case STATE_READ_REAL:
      {
        if (whitespace(c) || c == '(' || c == ')' || c == ']')
        {
          state->str[state->str_pos] = '\0';
          f8 n = strtod(state->str, NULL);
          obj_to_add = MAKE_REAL(n);
          state->state = STATE_NEXT_TOKEN;
          goto add_object;
        }
        else
        {
          if (c == '.' || c == 'e' || c == 'E')
          {
            //state->state = STATE_READ_REAL;
          }
          state->str[state->str_pos++] = c;
          state->pos++;
        }
      }
      break;
    case STATE_READ_SYMBOL:
      {
        if (whitespace(c) || c == '(' || c == ')' || c == '[' || c == ']')
        {
          /* end of symbol */
          state->str[state->str_pos] = '\0';
          obj o = make_symbol(interp, state->str);

          if (c == '[')
          {
            /* next parsed object - until closing bracket, should be added to aindex list */
            state->pos++;
            obj tmp = make_array(interp, 2, interp->s_aindex, o);
            array_add_obj(interp, state->stack[state->stack_pos], tmp);
            state->stack_pos++;
            state->stack[state->stack_pos] = tmp;
            state->stack_expr_parse_type[state->stack_pos] = EXPR_INDEX; /* indexing expression */
            state->state = STATE_NEXT_TOKEN;
          }
          else
          {
            obj_to_add = o;
            state->state = STATE_NEXT_TOKEN;
            goto add_object;
          }
        }
        else
        {
          state->str[state->str_pos++] = c;
          state->pos++;
        }
      }
      break;
    case STATE_READ_STRING:
      {
        if (c == '\\')
        {
          state->state = STATE_READ_STRING_ESCAPED;
          state->pos++;
        }
        else if (c == '"')
        {
          obj_to_add = make_string(interp, state->str, state->str_pos, 1);
          state->pos++;
          state->state = STATE_NEXT_TOKEN;
          goto add_object;
        }
        else
        {
          state->str[state->str_pos++] = c;
          state->pos++;
        }
      }
      break;
    case STATE_READ_STRING_ESCAPED:
      {
        switch (c)
        {
          case 'r':
            state->str[state->str_pos++] = '\r';
            state->pos++;
            break;
          case 'n':
            state->str[state->str_pos++] = '\n';
            state->pos++;
            break;
          case 't':
            state->str[state->str_pos++] = '\t';
            state->pos++;
            break;
          case '\\':
          case '"':
            state->str[state->str_pos++] = c;
            state->pos++;
            break;
          default:
            PRINT_ERROR("Unknown escaped char: %c\n", c);
            state->pos++;
            break;
        }

        state->state = STATE_READ_STRING;
      }
      break;
    case STATE_READ_COMMENT_LINE:
      {
        if (c == '\n')
          state->state = STATE_NEXT_TOKEN;

        state->pos++;
      }
      break;
    case STATE_READ_COMMENT_C:
      {
        if (c == '*')
          state->state = STATE_READ_COMMENT_C_STAR;

        state->pos++;
      }
      break;
    case STATE_READ_COMMENT_C_STAR:
      {
        state->state = (c == '/') ? STATE_NEXT_TOKEN : STATE_READ_COMMENT_C;
        state->pos++;
      }
      break;
    default:
      return;
      break;
  }

  return;

add_object:
  switch (state->stack_expr_parse_type[state->stack_pos])
  {
    case EXPR_NORMAL:
      array_add_obj(interp, state->stack[state->stack_pos], obj_to_add);
      break;
    case EXPR_INDEX:
      array_add_obj(interp, state->stack[state->stack_pos], obj_to_add);
      break;
    default:
      PARSE_ERROR("Unknown expression type");
      break;
  }
}

u0 parse(interpreter_t *interp, parse_state *state)
{
  while (1)
  {
    if (state->state == STATE_NEXT_TOKEN)
    {
      while (state->pos != state->end && whitespace(*state->pos))
        state->pos++;
    }

    if (state->pos == state->end)
    {
      return;
    }

    i1 c = *state->pos;

    parse_character(c, interp, state);

    if (state->state == STATE_ERROR)
    {
      break;
    }
  }
}

i8 convert_to_escaped(i1 *out, i8 size, const i1 **in_str)
{
  i8 offset = 0;

  const i1 *in = *in_str;

  while (*in)
  {
    switch (*in)
    {
      case '\n':
        if (offset > size - 3)
          goto return_unfinished;
        out[offset++] = '\\';
        out[offset++] = 'n';
        break;
      case '\r':
        if (offset > size - 3)
          goto return_unfinished;
        out[offset++] = '\\';
        out[offset++] = 'r';
        break;
      case '\t':
        if (offset > size - 3)
          goto return_unfinished;
        out[offset++] = '\\';
        out[offset++] = 't';
        break;
      case '"':
        if (offset > size - 3)
          goto return_unfinished;
        out[offset++] = '\\';
        out[offset++] = '"';
        break;
      default:
        if (offset > size - 2)
          goto return_unfinished;
        if ((u1)*in < 0x20)
          out[offset++] = ' ';
        else
          out[offset++] = *in;
        break;
    }

    in++;
  }

  *in_str = in;
  out[offset] = '\0';

  return offset + 1;

return_unfinished:
  out[offset] = '\0';
  *in_str = in;
  return -1;
}

u0 print_element(char *str_out, size_t str_out_size, const array_t *arr, i8 i)
{
  const u1 *storage = &((const u1 *)arr->storage)[i * arr->element_size];

  if (arr->element_type == ET_I1)
    SNPRINTF(str_out, str_out_size, "%d", *(i1 *)storage);
  else if (arr->element_type == ET_U1)
    SNPRINTF(str_out, str_out_size, "%u", *(u1 *)storage);
  else if (arr->element_type == ET_I2)
    SNPRINTF(str_out, str_out_size, "%d", *(i2 *)storage);
  else if (arr->element_type == ET_U2)
    SNPRINTF(str_out, str_out_size, "%u", *(u2 *)storage);
  else if (arr->element_type == ET_I4)
    SNPRINTF(str_out, str_out_size, "%d", *(i4 *)storage);
  else if (arr->element_type == ET_U4)
    SNPRINTF(str_out, str_out_size, "%u", *(u4 *)storage);
  else if (arr->element_type == ET_I8)
    SNPRINTF(str_out, str_out_size, "%lld", *(i8 *)storage);
  else if (arr->element_type == ET_U8)
    SNPRINTF(str_out, str_out_size, "%llu", *(u8 *)storage);
  else if (arr->element_type == ET_F4)
    SNPRINTF(str_out, str_out_size, "%f", *(f4 *)storage);
  else if (arr->element_type == ET_F8)
    SNPRINTF(str_out, str_out_size, "%f", *(f8 *)storage);
}

i8 print_object_gen(int mode, io_stream_t stream, i1 *out, size_t out_size, obj o, i8 no_string_quotes)
{
#define MAX_PRINT_ARRAY_ELEMENTS 100
  if (IS_NONE(o))
  {
    return print_string_or_stream(mode, stream, out, out_size, "None");
  }
  else if (IS_STRING(o))
  {
    if (no_string_quotes)
    {
      return print_string_or_stream(mode, stream, out, out_size, "%s", GET_STRING_STORAGE(o));
    }
    else
    {
      const i1 *str = GET_STRING_STORAGE(o);
      i8 offset = 0;
      offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset, "\"");
      char tmp[32];
      i8 res;
      do
      {
        res = convert_to_escaped(tmp, sizeof(tmp), &str);
        offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset - 1, "%s", tmp);
      }
      while (res < 0);
      offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset, "\"");

      return offset;
    }
  }
  else if (IS_ARRAY(o))
  {
    i8 offset = 0;
    array_t *l = GET_ARR(o);

    if (IS_OBJ_ARRAY(o))
    {
      offset += print_string_or_stream(mode, stream, out, out_size, "(");

      i8 num_print_elements = MIN_MACRO(l->size, MAX_PRINT_ARRAY_ELEMENTS);
      for (i8 i = 0; i < num_print_elements; i++)
      {
        offset += print_object_gen(mode, stream, &out[offset], out_size - offset, ((obj *)l->storage)[i], no_string_quotes);
        if (i != (l->size - 1))
          offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset, " ");
      }
      if (l->size > MAX_PRINT_ARRAY_ELEMENTS)
      {
        offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset, " ... %ld elements in total ...",
          l->size);
      }
      offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset, ")");
    }
    else
    {
      offset += print_string_or_stream(mode, stream, out, out_size, "A(");
      char tmp[32];
      i8 num_print_elements = MIN_MACRO(l->size, MAX_PRINT_ARRAY_ELEMENTS);
      for (i8 i = 0; i < num_print_elements; i++)
      {
        print_element(tmp, sizeof(tmp), l, i);
        offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset, "%s", tmp);
        if (i != (l->size - 1))
          offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset, " ");
      }
      if (l->size > MAX_PRINT_ARRAY_ELEMENTS)
      {
        offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset, " ... %ld elements in total ...",
          l->size);
      }
      offset += print_string_or_stream(mode, stream, &out[offset], out_size - offset, ")");
    }
    return offset;
  }
  else if (IS_INTEGER(o))
  {
    return print_string_or_stream(mode, stream, out, out_size, "%lld", GET_INTEGER(o));
  }
  else if (IS_REAL(o))
  {
    return print_string_or_stream(mode, stream, out, out_size, "%f", TO_F8(o));
  }
  else if (IS_SYMBOL(o))
  {
    return print_string_or_stream(mode, stream, out, out_size, "%s", get_symbol_string(o));
  }
  else if (IS_FUNCTION(o))
  {
    return print_string_or_stream(mode, stream, out, out_size, "[func %llx]", (u8)o);
  }
  else
  {
    return print_string_or_stream(mode, stream, out, out_size, "[%llx]", (u8)o);
  }
}

u0 print_object(io_stream_t f, obj o)
{
  print_object_gen(0, f, NULL, 0, o, 0);
}

i8 print_object_string(i1 *out, size_t out_size, obj o)
{
  return print_object_gen(1, 0, out, out_size, o, 0);
}

u0 print_object_no_quotes(io_stream_t f, obj o)
{
  print_object_gen(0, f, NULL, 0, o, 1);
}

u0 free_object(interpreter_t *interp, obj o)
{
  // FMT(STDOUT_H, "Freeing 0x%llx: ", o); print_object(o); FMT(STDOUT_H, "\n");

  if (IS_ARRAY(o))
  {
    array_t *l = GET_ARR(o);
    if (IS_OBJ_ARRAY(o))
    {
      for (i8 i = 0; i < l->size; i++)
      {
        DEC(interp, ((obj *)l->storage)[i]);
      }
    }
    free(l->storage);
    free(l);
  }
  else if (IS_SYMBOL(o) && !IS_NONE(o))
  {
    PRINT_ERROR("Freeing symbol - shouldn't happen: ");
    print_object(STDERR_H, o);
    FMT(STDERR_H, "\n");

    symbol_t *sym = (symbol_t *)GET_POINTER(o);
    free_object(interp, sym->value);
    free_object(interp, sym->function_value);
    free(sym->name);
    free(sym);
  }
  else if (IS_FUNCTION(o))
  {
    function_t *f = (function_t *)GET_POINTER(o);
    if (f->ptr && f->function_type == FT_BYTECODE)
      free(f->ptr);
    DEC(interp, f->immediates);
    DEC(interp, f->arg_types);
    DEC(interp, f->code);
    DEC(interp, f->ir_code);
    free(f);
  }
}

const i1 *bytecode_name(u8 code)
{
  for (i8 i = 0; i < instruction_count; i++)
  {
    if (code == instruction_address[i])
    {
      return bytecode_names[i];
    }
  }

  return NULL;
}

u0 print_bytecode(const u8 *code, i8 count)
{
  FMT(STDOUT_H, "Bytecode (%lld elements) offset 0x%llx:\n", count, (u8)code);
  for (i8 i = 0; i < count; i++)
  {
    const i1 *name = bytecode_name(code[i]);
    if (name)
      FMT(STDOUT_H, "[0x%04llx]: 0x%llx = %s\n", 8 * i, code[i], name);
    else
      FMT(STDOUT_H, "[0x%04llx]: 0x%llx = %lld\n", 8 * i, code[i], code[i]);
  }
}

i8 is_arg_variable(interpreter_t *interp, obj sym, i8 arg_pos, i8 type)
{
  static const struct { i8 sym_offset; u8 variable_arg_mask_write; u8 variable_arg_mask_read; }
  variable_positions[] = {
    { offsetof(interpreter_t, s_moverr), (1 << 0), (1 << 1)},
    { offsetof(interpreter_t, s_moveri), (1 << 0), 0},
    { offsetof(interpreter_t, s_moverglobal), (1 << 0), 0},
    { offsetof(interpreter_t, s_moveglobalr), 0, (1 << 1)},
    { offsetof(interpreter_t, s_moveglobalfuni), 0, 0},
    { offsetof(interpreter_t, s_addrr), (1 << 0), (1 << 0) | (1 << 1)},
    { offsetof(interpreter_t, s_addri), (1 << 0), (1 << 0)},
    { offsetof(interpreter_t, s_subrr), (1 << 0), (1 << 0) | (1 << 1)},
    { offsetof(interpreter_t, s_mulrr), (1 << 0), (1 << 0) | (1 << 1)},
    { offsetof(interpreter_t, s_mulri), (1 << 0), (1 << 0)},
    { offsetof(interpreter_t, s_divrr), (1 << 0), (1 << 0) | (1 << 1)},
    { offsetof(interpreter_t, s_cmprr), 0, (1 << 0) | (1 << 1)},
    { offsetof(interpreter_t, s_cmpri), 0, (1 << 0)},
    { offsetof(interpreter_t, s_jump), 0, 0},
    { offsetof(interpreter_t, s_inc_jump_lt), (1 << 0), (1 << 0) | (1 << 1)},
    { offsetof(interpreter_t, s_jump_eq), 0, 0},
    { offsetof(interpreter_t, s_jump_ne), 0, 0},
    { offsetof(interpreter_t, s_jump_gt), 0, 0},
    { offsetof(interpreter_t, s_jump_lt), 0, 0},
    { offsetof(interpreter_t, s_jump_ge), 0, 0},
    { offsetof(interpreter_t, s_jump_le), 0, 0},
    { offsetof(interpreter_t, s_retc), 0, (1 << 0)},
    { offsetof(interpreter_t, s_ret), 0, (1 << 0)},
    { offsetof(interpreter_t, s_call), (1 << 1), 0},
    { offsetof(interpreter_t, s_call_internal), (1 << 0), 0},
    { offsetof(interpreter_t, s_call_external), (1 << 0), 0},
    { offsetof(interpreter_t, s_call_external2), (1 << 0), 0},
    { offsetof(interpreter_t, s_incref), (1 << 0), 0},
    { offsetof(interpreter_t, s_decref), (1 << 0), 0},
    { offsetof(interpreter_t, s_aindexr), (1 << 2), (1 << 0) | (1 << 1)},
    { offsetof(interpreter_t, s_aindexi), (1 << 2), (1 << 0)},
    { offsetof(interpreter_t, s_saindexr), 0, (1 << 0) | (1 << 1) | (1 << 2)},
  };

  for (i8 i = 0; i < ARRAY_SIZE(variable_positions); i++)
  {
    if (SYMBOL_OBJ(interp, variable_positions[i].sym_offset) == sym)
    {
      if (type == 0)
        return (variable_positions[i].variable_arg_mask_write & (1ULL << arg_pos)) ||
          (variable_positions[i].variable_arg_mask_read & (1ULL << arg_pos));
      else if (type == 1)
        return (variable_positions[i].variable_arg_mask_read & (1ULL << arg_pos));
      else if (type == 2)
        return (variable_positions[i].variable_arg_mask_write & (1ULL << arg_pos)) ;
    }
  }

  return 0;
}

// Produce the number in bytecode from the register idx
#define BYTECODE_REGISTER_OFFSET(x) (x)

u0 specialize_instruction2(compiler_state *cs, i8 inst, i8 reg0, i8 reg1)
{
  i8 reg0_relative = reg0 - cs->register_file_start;
  i8 reg1_relative = reg1 - cs->register_file_start;

  i8 reg0_cpu = (reg0_relative >= 0 && reg0_relative < NUM_CPU_REGISTERS && reg0_relative < cs->register_file_end);
  i8 reg1_cpu = (reg1_relative >= 0 && reg1_relative < NUM_CPU_REGISTERS && reg1_relative < cs->register_file_end);

  if (reg0_cpu && reg1_cpu)
  {
    VEC_PUSHBACK(u8, cs->bytecode, I(inst + 1 + (2 * NUM_CPU_REGISTERS) + reg0_relative * NUM_CPU_REGISTERS + reg1_relative));
  }
  else if (reg0_cpu)
  {
    VEC_PUSHBACK(u8, cs->bytecode, I(inst + 1 + 2 * reg0_relative + 1));
    VEC_PUSHBACK(u8, cs->bytecode, BYTECODE_REGISTER_OFFSET(reg1));
  }
  else if (reg1_cpu)
  {
    VEC_PUSHBACK(u8, cs->bytecode, I(inst + 1 + 2 * reg1_relative));
    VEC_PUSHBACK(u8, cs->bytecode, BYTECODE_REGISTER_OFFSET(reg0));
  }
  else
  {
    VEC_PUSHBACK(u8, cs->bytecode, I(inst));
    VEC_PUSHBACK(u8, cs->bytecode, BYTECODE_REGISTER_OFFSET(reg0));
    VEC_PUSHBACK(u8, cs->bytecode, BYTECODE_REGISTER_OFFSET(reg1));
  }
}

u0 specialize_instruction1(compiler_state *cs, i8 inst, i8 reg0)
{
  i8 reg0_relative = reg0 - cs->register_file_start;

  i8 reg0_cpu = (reg0_relative >= 0 && reg0_relative < NUM_CPU_REGISTERS && reg0_relative < cs->register_file_end);

  if (reg0_cpu)
  {
    VEC_PUSHBACK(u8, cs->bytecode, I(inst + 1 + reg0_relative));
  }
  else
  {
    VEC_PUSHBACK(u8, cs->bytecode, I(inst));
    VEC_PUSHBACK(u8, cs->bytecode, BYTECODE_REGISTER_OFFSET(reg0));
  }
}

u0 specialize_instruction_arg(compiler_state *cs, i8 inst, i8 reg0, i8 reg1, i8 num_dst_registers)
{
  if (reg1 < 0)
  {
    /* immediate argument */
    if (reg0 < num_dst_registers)
    {
      VEC_PUSHBACK(u8, cs->bytecode, I(inst + (num_dst_registers + 1) * (NUM_CPU_REGISTERS + 1) + 1 + reg0));
    }
    else
    {
      VEC_PUSHBACK(u8, cs->bytecode, I(inst + (num_dst_registers + 1) * (NUM_CPU_REGISTERS + 1)));
      VEC_PUSHBACK(u8, cs->bytecode, reg0);
    }
  }
  else
  {
    i8 reg1_relative = reg1 - cs->register_file_start;

    i8 reg1_cpu = (reg1_relative >= 0 && reg1_relative < NUM_CPU_REGISTERS && reg1_relative < cs->register_file_end);

    if (reg1_cpu && reg0 < num_dst_registers)
    {
      VEC_PUSHBACK(u8, cs->bytecode, I(inst + (num_dst_registers + 1) * (reg1_relative + 1) + 1 + reg0));
    }
    else if (reg1_cpu)
    {
      VEC_PUSHBACK(u8, cs->bytecode, I(inst + (num_dst_registers + 1) * (reg1_relative + 1)));
      VEC_PUSHBACK(u8, cs->bytecode, BYTECODE_REGISTER_OFFSET(reg0));
    }
    else if (reg0 < num_dst_registers)
    {
      VEC_PUSHBACK(u8, cs->bytecode, I(inst + 1 + reg0));
      VEC_PUSHBACK(u8, cs->bytecode, BYTECODE_REGISTER_OFFSET(reg1));
    }
    else
    {
      VEC_PUSHBACK(u8, cs->bytecode, I(inst));
      VEC_PUSHBACK(u8, cs->bytecode, reg0);
      VEC_PUSHBACK(u8, cs->bytecode, BYTECODE_REGISTER_OFFSET(reg1));
    }
  }
}

i8 compile_to_bytecode(interpreter_t *interp, obj ir_code, compiler_state *cs)
{
  /* perform register allocation and produce bytecode optimized for performance */

  typedef struct {
    i8 kind;
    i8 start;
    i8 end;
    i8 reads;
    i8 writes;
    i8 register_idx;
  } variable_data_t;
  i8 var_count = cs->vars_count;
  FMT(STDOUT_H, "Var count %lld\n", var_count);

  variable_data_t *vars = MALLOC_ARRAY(variable_data_t, var_count);

  i8 max_variable = -1;
  i8 max_call_arg = 0;
  for (i8 i = 0; i < var_count; i++)
  {
    vars[i].kind = cs->vars[i].kind;

    if (vars[i].kind == VAR_ARGUMENT) /* arguments are already located */
      vars[i].register_idx = -(cs->vars[i].var_sequence_number + 1);

    if (vars[i].kind == VAR_CALL_ARGUMENT) /* call arguments must be on top of stack */
    {
      vars[i].register_idx = -(cs->vars[i].var_sequence_number + 1);
      if (max_call_arg < cs->vars[i].var_sequence_number + 1)
        max_call_arg = cs->vars[i].var_sequence_number + 1;
    }

    vars[i].start = -1;
    vars[i].end = -1;
    vars[i].reads = 0;
    vars[i].writes = 0;
  }

  /* first pass: find lexical variable lifetime (IR code start/end indices) */
  {
    for (i8 i_ir_code = 0; i_ir_code < ASIZE(ir_code); i_ir_code++)
    {
      obj a = NTH(ir_code, i_ir_code);

      if (!IS_OBJ_ARRAY(a))
      {
        PRINT_ERROR("A vector expected\n");
        continue;
      }

      obj sym = NTH(a, 0);
      for (i8 i = 1; i < ASIZE(a); i++)
      {
        if (is_arg_variable(interp, sym, i - 1, 0))
        {
          // FMT(STDOUT_H, "argument %lld is variable in symbol ", i - 1); print_object(sym); FMT(STDOUT_H, "\n");
          /* update variable use */
          if (!IS_INTEGER(NTH(a, i)))
          {
            PRINT_ERROR("Variable in IR code should be an integer\n");
          }
          else
          {
            i8 var = GET_INTEGER(NTH(a, i));
            if (var >= 0) /* negative variable number is reserved */
            {
              if (max_variable < var) max_variable = var;
              if (vars[var].start == -1) vars[var].start = i_ir_code;
              if (vars[var].end < i_ir_code) vars[var].end = i_ir_code;

              if (is_arg_variable(interp, sym, i - 1, 1)) vars[var].reads++;
              if (is_arg_variable(interp, sym, i - 1, 2)) vars[var].writes++;
            }
          }
        }
      }
    }

    for (i8 i = 0; i <= max_variable; i++)
    {
      FMT(STDOUT_H, "Variable %lld: ", i);
      print_object(STDOUT_H, cs->vars[i].sym);
      FMT(STDOUT_H, " start %lld end %lld reads %lld writes %lld", vars[i].start, vars[i].end, vars[i].reads, vars[i].writes);
      if (cs->vars[i].kind == VAR_CALL_ARGUMENT)
        FMT(STDOUT_H, " (CALL ARGUMENT %lld)", cs->vars[i].var_sequence_number);
      else if (cs->vars[i].kind == VAR_ARGUMENT)
        FMT(STDOUT_H, " (FUNCTION ARGUMENT %lld)", cs->vars[i].var_sequence_number);
      else if (cs->vars[i].kind == VAR_TEMPORARY)
        FMT(STDOUT_H, " (TEMPORARY %lld)", cs->vars[i].var_sequence_number);
      else if (cs->vars[i].kind == VAR_LEXICAL)
        FMT(STDOUT_H, " (LEXICAL %lld)", cs->vars[i].var_sequence_number);

      FMT(STDOUT_H, "\n");
    }
  }

  /* second pass: allocate lexical variables into register slots */
  i8 reg_taken[1000];
  i8 reg_taken_write_reads[1000];
  i8 reg_taken_num_vars[1000];
  i8 max_reg_taken = 0;
  memory_set(reg_taken, 0, sizeof(reg_taken));
  memory_set(reg_taken_write_reads, 0, sizeof(reg_taken_write_reads));
  memory_set(reg_taken_num_vars, 0, sizeof(reg_taken_num_vars));

  for (i8 i_ir_code = 0; i_ir_code < ASIZE(ir_code); i_ir_code++)
  {
    /* allocate registers */
    for (i8 i_var = 0; i_var < var_count; i_var++)
    {
      if (vars[i_var].kind == VAR_ARGUMENT || vars[i_var].kind == VAR_CALL_ARGUMENT)
        continue;

      if (vars[i_var].start == i_ir_code)
      {
        i8 i_reg_alloc = -1;
        /* allocate a slot */
        for (i8 i_reg = 0; i_reg < max_reg_taken; i_reg++)
        {
          if (!reg_taken[i_reg])
          {
            i_reg_alloc = i_reg;
            break;
          }
        }

        if (i_reg_alloc < 0)
        {
          i_reg_alloc = max_reg_taken;
          max_reg_taken++;
        }

        FMT(STDOUT_H, "Allocate variable %lld to register %lld\n", i_var, i_reg_alloc);
        vars[i_var].register_idx = i_reg_alloc;
        reg_taken[i_reg_alloc] = 1;
        reg_taken_write_reads[i_reg_alloc] += vars[i_var].reads + vars[i_var].writes;
        reg_taken_num_vars[i_reg_alloc]++;
      }
    }

    for (i8 i_var = 0; i_var < var_count; i_var++)
    {
      if (vars[i_var].kind == VAR_ARGUMENT || vars[i_var].kind == VAR_CALL_ARGUMENT)
        continue;

      if (vars[i_var].end == i_ir_code)
      {
        /* not taken anymore in next iteration */
        if (vars[i_var].register_idx >= 0)
          reg_taken[vars[i_var].register_idx] = 0;
        else
          PRINT_ERROR("Shouldn't happen - register_idx negative\n");
      }
    }
  }

  for (i8 i = 0; i < max_reg_taken; i++)
  {
    FMT(STDOUT_H, "reg %lld: reads-writes %lld num vars %lld\n", i, reg_taken_write_reads[i], reg_taken_num_vars[i]);
  }

  /* now position variables that are call arguments on top of stack */
#define STACK_TAIL_DATA 1 // added entry at the bottom of stack
#define STACK_CALL_FRAME_DATA 2 // size of the stack entry when calling a function
  for (i8 i_var = 0; i_var < var_count; i_var++)
  {
    if (vars[i_var].kind == VAR_ARGUMENT)
    {
      /* rsi + arg space + variable space + 2 spaces (function object, return adresse), then 0, 1, 2 */
      vars[i_var].register_idx = max_reg_taken + max_call_arg + STACK_CALL_FRAME_DATA + 2 * STACK_TAIL_DATA + cs->vars[i_var].var_sequence_number;
    }
    else if (vars[i_var].kind == VAR_CALL_ARGUMENT)
    {
      vars[i_var].register_idx = STACK_TAIL_DATA + cs->vars[i_var].var_sequence_number; /* from rsi+8 ptr and up, 0, 1, 2... */
    }
    else
    {
      vars[i_var].register_idx += STACK_TAIL_DATA + max_call_arg; /* move variables into space 'above' call argument space */
    }
  }

  FMT(STDOUT_H, "Stack map: Call argument space %d-%lld, registers %lld-%lld, function arguments %lld-\n",
      STACK_TAIL_DATA, STACK_TAIL_DATA + max_call_arg - 1, STACK_TAIL_DATA + max_call_arg,
      STACK_TAIL_DATA + max_call_arg + max_reg_taken - 1,
      2 * STACK_TAIL_DATA + max_reg_taken + max_call_arg + STACK_CALL_FRAME_DATA);

  cs->register_file_start = STACK_TAIL_DATA + max_call_arg;
  cs->register_file_end = STACK_TAIL_DATA + max_call_arg + max_reg_taken;

  /* third step: map reg indices to hw/registers + register file (stack) */

#define REGISTER_NUMBER(x) (vars[GET_INTEGER(x)].register_idx)

  vec_t *fix_labels = VEC_ALLOC(u8, 0, 20);
  vec_t *label_positions = VEC_ALLOC(u8, 0, 20);
  VEC_FILL(u8, label_positions, 10000, -1);

  // total reserved stack - space for local variables and call arguments
  i8 stack_size = 8 * (max_reg_taken + max_call_arg + 1) /* for added stack offset from frame entry */;

  {
    VEC_PUSHBACK(u8, cs->bytecode, I(I_RESERVE_STACK));
    VEC_PUSHBACK(u8, cs->bytecode, stack_size);
  }

  for (i8 i = 0; i < ASIZE(ir_code); i++)
  {
    obj a = NTH(ir_code, i);
    // FMT(STDOUT_H, "IR Code [%lld] 0x%llx:\n", i, a); print_object(STDOUT_H, a); FMT(STDOUT_H, "\n");

    if (!IS_OBJ_ARRAY(a))
    {
      PRINT_ERROR("A vector expected\n");
    }
    else
    {
      obj sym = NTH(a, 0);

      i8 i_bytecode_offset = VEC_SIZE(u8, cs->bytecode);

      if (sym == interp->s_label)
      {
        i8 num = GET_INTEGER(NTH(a, 1));

        VEC_NTH(u8, label_positions, num) = i_bytecode_offset;
      }
      else if (sym == interp->s_moverr)
      {
        specialize_instruction2(cs, I_MOVERR, REGISTER_NUMBER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)));
      }
      else if (sym == interp->s_moveri)
      {
        specialize_instruction1(cs, I_MOVERI, REGISTER_NUMBER(NTH(a, 1)));
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));

        if (IS_ALLOCATED(NTH(a, 2)))
          array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_moverglobal)
      {
        specialize_instruction1(cs, I_MOVERGLOBAL, REGISTER_NUMBER(NTH(a, 1)));
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
      }
      else if (sym == interp->s_moveglobalr)
      {
        specialize_instruction1(cs, I_MOVEGLOBALR, REGISTER_NUMBER(NTH(a, 2)));
        /* reg number in 2nd argument becomes the first argument - because of ASM implementation */
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 1));
      }
      else if (sym == interp->s_moveglobalfuni)
      {
        VEC_PUSHBACK(u8, cs->bytecode, I(I_MOVEGLOBALFUNI));
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 1));
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        if (IS_ALLOCATED(NTH(a, 2)))
          array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_addrr)
      {
        specialize_instruction2(cs, I_ADDRR, REGISTER_NUMBER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)));
      }
      else if (sym == interp->s_addri)
      {
        specialize_instruction1(cs, IS_INTEGER(NTH(a, 2)) ? I_ADDRI : I_ADDRIF, REGISTER_NUMBER(NTH(a, 1)));
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        if (IS_ALLOCATED(NTH(a, 2)))
          array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_subrr)
      {
        specialize_instruction2(cs, I_SUBRR, REGISTER_NUMBER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)));
      }
      else if (sym == interp->s_mulrr)
      {
        specialize_instruction2(cs, I_MULRR, REGISTER_NUMBER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)));
      }
      else if (sym == interp->s_mulri)
      {
        specialize_instruction1(cs, IS_INTEGER(NTH(a, 2)) ? I_MULRI : I_MULRIF, REGISTER_NUMBER(NTH(a, 1)));
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        if (IS_ALLOCATED(NTH(a, 2)))
          array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_divrr)
      {
        specialize_instruction2(cs, I_DIVRR, REGISTER_NUMBER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)));
      }
      else if (sym == interp->s_negate)
      {
        specialize_instruction1(cs, I_NEGATER, REGISTER_NUMBER(NTH(a, 1)));
      }
      else if (sym == interp->s_jump)
      {
        VEC_PUSHBACK(u8, cs->bytecode, I(I_JMP));
        VEC_PUSHBACK(u8, cs->bytecode, GET_INTEGER(NTH(a, 1)));
        VEC_PUSHBACK(u8, fix_labels, GET_INTEGER(NTH(a, 1)));
        VEC_PUSHBACK(u8, fix_labels, VEC_SIZE(u8, cs->bytecode) - 1);
        VEC_PUSHBACK(u8, fix_labels, i_bytecode_offset);
      }
      else if (sym == interp->s_cmprr)
      {
        specialize_instruction2(cs, I_CMPRR, REGISTER_NUMBER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)));
      }
      else if (sym == interp->s_cmpri)
      {
        specialize_instruction1(cs, I_CMPRI, REGISTER_NUMBER(NTH(a, 1)));
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        if (IS_ALLOCATED(NTH(a, 2)))
          array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_inc_jump_lt)
      {
        specialize_instruction2(cs, I_INC_JMP_LTRR, REGISTER_NUMBER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)));
        VEC_PUSHBACK(u8, cs->bytecode, GET_INTEGER(NTH(a, 3)));
        VEC_PUSHBACK(u8, fix_labels, GET_INTEGER(NTH(a, 3)));
        VEC_PUSHBACK(u8, fix_labels, VEC_SIZE(u8, cs->bytecode) - 1);
        VEC_PUSHBACK(u8, fix_labels, i_bytecode_offset);
      }
#define JMP_FORM(sym_compare, inst) \
      else if (sym == (sym_compare)) \
      { \
        VEC_PUSHBACK(u8, cs->bytecode, I((inst))); \
        VEC_PUSHBACK(u8, cs->bytecode, GET_INTEGER(NTH(a, 1))); \
        VEC_PUSHBACK(u8, fix_labels, GET_INTEGER(NTH(a, 1))); \
        VEC_PUSHBACK(u8, fix_labels, VEC_SIZE(u8, cs->bytecode) - 1); \
        VEC_PUSHBACK(u8, fix_labels, i_bytecode_offset); \
      }
      JMP_FORM(interp->s_jump_eq, I_JMP_EQ)
        JMP_FORM(interp->s_jump_ne, I_JMP_NE)
        JMP_FORM(interp->s_jump_gt, I_JMP_GT)
        JMP_FORM(interp->s_jump_lt, I_JMP_LT)
        JMP_FORM(interp->s_jump_ge, I_JMP_GE)
        JMP_FORM(interp->s_jump_le, I_JMP_LE)
      else if (sym == interp->s_retc)
      {
        specialize_instruction1(cs, I_RETCR, REGISTER_NUMBER(NTH(a, 1)));
      }
      else if (sym == interp->s_ret)
      {
        specialize_instruction1(cs, I_RETR, REGISTER_NUMBER(NTH(a, 1)));
      }
      else if (sym == interp->s_call)
      {
        VEC_PUSHBACK(u8, cs->bytecode, I(I_CALL));
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 1));
        specialize_instruction1(cs, I_MOVERETVALR, REGISTER_NUMBER(NTH(a, 2)));
        if (IS_ALLOCATED(NTH(a, 1)))
          array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 1)));
      }
      else if (sym == interp->s_call_internal)
      {
        if (GET_INTEGER(NTH(a, 1)) < 0)
          VEC_PUSHBACK(u8, cs->bytecode, I(I_CALLINTN));
        else
          specialize_instruction1(cs, I_CALLINTR, REGISTER_NUMBER(NTH(a, 1)));

        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        VEC_PUSHBACK(u8, cs->bytecode, GET_INTEGER(NTH(a, 3)));

        if (IS_ALLOCATED(NTH(a, 2)))
          array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_call_external)
      {
        if (GET_INTEGER(NTH(a, 1)) < 0)
          VEC_PUSHBACK(u8, cs->bytecode, I(I_CALLEXTN));
        else
          specialize_instruction1(cs, I_CALLEXTR, REGISTER_NUMBER(NTH(a, 1)));

        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        VEC_PUSHBACK(u8, cs->bytecode, GET_INTEGER(NTH(a, 3)));

        if (IS_ALLOCATED(NTH(a, 2)))
          array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_incref)
      {
        specialize_instruction1(cs, I_INCREFR, REGISTER_NUMBER(NTH(a, 1)));
      }
      else if (sym == interp->s_decref)
      {
        specialize_instruction1(cs, I_DECREFR, REGISTER_NUMBER(NTH(a, 1)));
      }
      else if (sym == interp->s_aindexr)
      {
        specialize_instruction2(cs, I_AINDEXRR, REGISTER_NUMBER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)));
        specialize_instruction1(cs, I_MOVERETVALR, REGISTER_NUMBER(NTH(a, 3)));
      }
      else if (sym == interp->s_aindexi)
      {
        specialize_instruction1(cs, I_AINDEXRI, REGISTER_NUMBER(NTH(a, 1)));
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        specialize_instruction1(cs, I_MOVERETVALR, REGISTER_NUMBER(NTH(a, 3)));
      }
      else if (sym == interp->s_saindexr)
      {
        specialize_instruction2(cs, I_SAINDEXRR, REGISTER_NUMBER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)));
        specialize_instruction1(cs, I_SAVALUER, REGISTER_NUMBER(NTH(a, 3)));
      }
      else if (sym == interp->s_ulongarg)
      {
        specialize_instruction_arg(cs, I_ULONGARGRR, GET_INTEGER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)), NUM_INT_REG_ARGUMENTS);
      }
      else if (sym == interp->s_ulongargi)
      {
        specialize_instruction_arg(cs, I_ULONGARGRR, GET_INTEGER(NTH(a, 1)), -1, NUM_INT_REG_ARGUMENTS);
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        if (IS_ALLOCATED(NTH(a, 2))) array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_ptrarg)
      {
        specialize_instruction_arg(cs, I_PTRARGRR, GET_INTEGER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)), NUM_INT_REG_ARGUMENTS);
      }
      else if (sym == interp->s_ptrargi)
      {
        specialize_instruction_arg(cs, I_PTRARGRR, GET_INTEGER(NTH(a, 1)), -1, NUM_INT_REG_ARGUMENTS);
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        if (IS_ALLOCATED(NTH(a, 2))) array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_f4arg)
      {
        specialize_instruction_arg(cs, I_F4ARGRR, GET_INTEGER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)), NUM_FLOAT_REG_ARGUMENTS);
      }
      else if (sym == interp->s_f4argi)
      {
        specialize_instruction_arg(cs, I_F4ARGRR, GET_INTEGER(NTH(a, 1)), -1, NUM_FLOAT_REG_ARGUMENTS);
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        if (IS_ALLOCATED(NTH(a, 2))) array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_f8arg)
      {
        specialize_instruction_arg(cs, I_F8ARGRR, GET_INTEGER(NTH(a, 1)), REGISTER_NUMBER(NTH(a, 2)), NUM_FLOAT_REG_ARGUMENTS);
      }
      else if (sym == interp->s_f8argi)
      {
        specialize_instruction_arg(cs, I_F8ARGRR, GET_INTEGER(NTH(a, 1)), -1, NUM_FLOAT_REG_ARGUMENTS);
        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2));
        if (IS_ALLOCATED(NTH(a, 2))) array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_call_external2)
      {
        if (GET_INTEGER(NTH(a, 1)) < 0)
          VEC_PUSHBACK(u8, cs->bytecode, I(I_CALLEXT2N));
        else
          specialize_instruction1(cs, I_CALLEXT2R, REGISTER_NUMBER(NTH(a, 1)));

        VEC_PUSHBACK(u8, cs->bytecode, NTH(a, 2)); /* function object */
        VEC_PUSHBACK(u8, cs->bytecode, GET_INTEGER(NTH(a, 3))); /* number of arguments */

        if (IS_ALLOCATED(NTH(a, 2)))
          array_add_obj(interp, cs->immediates, INC(interp, NTH(a, 2)));
      }
      else if (sym == interp->s_call_external2_prepare)
      {
        VEC_PUSHBACK(u8, cs->bytecode, I(I_CALLEXT2_PREPARE));
        VEC_PUSHBACK(u8, cs->bytecode, GET_INTEGER(NTH(a, 1))); /* stack area to reserve on rsp in bytes */
      }
      else if (sym == interp->s_debug_break)
      {
        VEC_PUSHBACK(u8, cs->bytecode, I(I_DEBUG_BREAK));
      }
      else
      {
        FMT(STDERR_H, "Bytecode: unknown instruction: ");
        print_object(STDERR_H, sym);
        FMT(STDERR_H, "\n");
        return -1;
      }
    }
  }

  FMT(STDOUT_H, "Fixing jump offsets...\n");

  for (i8 i = 0; i < VEC_SIZE(u8, fix_labels); i += 3)
  {
    i8 label_num = VEC_NTH(u8, fix_labels, i);
    i8 write_pos = VEC_NTH(u8, fix_labels, i + 1);
    i8 offset_origin = VEC_NTH(u8, fix_labels, i + 2);

    i8 label_pos =  VEC_SIZE(u8, label_positions) > label_num ? VEC_NTH(u8, label_positions, label_num) : -1;

    if (label_pos >= 0)
    {
      i8 offset = label_pos - offset_origin;
      FMT(STDOUT_H, "Label %lld is at pos %lld; write jump offset at pos %lld: %lld (* 8 bytes) (offset origin %lld)\n",
          label_num, label_pos, write_pos, offset, offset_origin);
      VEC_NTH(u8, cs->bytecode, write_pos) = 8 * offset; /* in bytes */
    }
    else
    {
      FMT(STDOUT_H, "Label %lld undefined (but referenced)\n", label_num);
    }
  }

  VEC_FREE(fix_labels);
  VEC_FREE(label_positions);
  free(vars);
  return 0;
}

#if 0
u0 *allocate_executable(size_t size)
{
  u0 *ptr = mmap(NULL, size, PROT_EXEC | PROT_READ | PROT_WRITE, MAP_ANON | MAP_SHARED, -1, 0);
  if (ptr == MAP_FAILED)
  {
    FMT(STDERR_H, "mmap (%s)", strerror(errno));
  }

  return ptr;
}

u0 free_executable(u0 *ptr, size_t size)
{
  munmap(ptr, size);
}

i8 compile_to_machinecode(interpreter_t *interp, obj ir_code, compiler_state *cs)
{
  /* perform register allocation and produce preprocessed bytecode for performance */
  vec_t *fix_labels = VEC_ALLOC(u8, 0, 20);
  vec_t *label_positions = VEC_ALLOC(u8, 0, 20);
  VEC_FILL(u8, label_positions, 10000, -1);

  i8 stack_size = 8 * cs->vars_count;

  cs->machinecode = allocate_executable(2 * 1024);
  memory_set(cs->machinecode, 0xcc, 2 * 1024);
  i8 pos = 0;
  u1 *code = &cs->machinecode[0];
  {
    /* reserve stack */

    // code[pos++] = 0xcc;

    // 0:	55                   	push   %rbp
    // 1:	48 89 e5             	mov    %rsp,%rbp
    memory_copy(&code[pos], "\x55\x48\x89\xe5", 4);
    pos += 4;
    // sub rsp, 1000
    memory_copy(&code[pos], "\x48\x81\xec", 3);
    pos += 3;
    memory_copy(&code[pos], &stack_size, 4);
    pos += 4;
    //VEC_PUSHBACK(u8, cs->bytecode, I(I_RESERVE_STACK));
    //VEC_PUSHBACK(u8, cs->bytecode, stack_size);
  }

  for (i8 i = 0; i < ASIZE(ir_code); i++)
  {
    obj a = NTH(ir_code, i);
    // FMT(STDOUT_H, "IR Code [%lld] 0x%llx:\n", i, a); print_object(STDOUT_H, a); FMT(STDOUT_H, "\n");

    if (!IS_OBJ_ARRAY(a))
    {
      PRINT_ERROR("A vector expected\n");
    }
    else
    {
      obj sym = NTH(a, 0);

      i8 i_bytecode_offset = pos;

      if (sym == interp->s_label)
      {
        i8 num = GET_INTEGER(NTH(a, 1));

        VEC_NTH(u8, label_positions, num) = i_bytecode_offset;
      }
      else if (sym == interp->s_moveri)
      {
        // 0:  48 b8 c0 c0 a0 a0 e0    movabs rax,0xf0f0e0e0a0a0c0c0
        // 7:  e0 f0 f0
        u8 val = NTH(a, 2);
        memory_copy(&code[pos], "\x48\xb8", 2);
        pos += 2;
        memory_copy(&code[pos], &val, 8);
        pos += 8;
        // a:  48 89 84 24 e8 03 00    mov    QWORD PTR [rsp+0x3e8],rax
        // 11: 00
        i8 reg = GET_INTEGER(NTH(a, 1));
        reg *= 8;
        memory_copy(&code[pos], "\x48\x89\x84\x24", 4);
        pos += 4;
        memory_copy(&code[pos], &reg, 4);
        pos += 4;
      }
      else if (sym == interp->s_moverr)
      {
      }
      else if (sym == interp->s_addrr)
      {
        {
          i8 reg = 8 * GET_INTEGER(NTH(a, 2));
          // 0:  48 8b 84 24 e8 03 00    mov    rax,QWORD PTR [rsp+0x3e8]
          // 7:  00
          memory_copy(&code[pos], "\x48\x8b\x84\x24", 4);
          pos += 4;
          memory_copy(&code[pos], &reg, 4);
          pos += 4;
        }

        {
          // 12: 48 01 84 24 e8 03 00    add    QWORD PTR [rsp+0x3e8],rax
          // 19: 00
          i8 reg = 8 * GET_INTEGER(NTH(a, 1));
          memory_copy(&code[pos], "\x48\x01\x84\x24", 4);
          pos += 4;
          memory_copy(&code[pos], &reg, 4);
          pos += 4;
        }

      }
      else if (sym == interp->s_addri)
      {
      }
      else if (sym == interp->s_jump)
      {
        // 2b: e9 d2 03 00 00          jmp    402 <test+0x3e8>
        memory_copy(&code[pos], "\xe9\x00\x00\x00\x00", 5);
        pos += 5;
        //VEC_PUSHBACK(u8, cs->bytecode, I(I_JMP));
        //VEC_PUSHBACK(u8, cs->bytecode, GET_INTEGER(NTH(a, 1)));
        VEC_PUSHBACK(u8, fix_labels, GET_INTEGER(NTH(a, 1))); /* label num */
        VEC_PUSHBACK(u8, fix_labels, pos - 4); /* write pos */
        VEC_PUSHBACK(u8, fix_labels, pos); /* offset calculation base */
      }
      else if (sym == interp->s_inc_jump_lt)
      {
        {
          i8 reg = 8 * GET_INTEGER(NTH(a, 1));
          // 0:  48 8b 84 24 e8 03 00    mov    rax,QWORD PTR [rsp+0x3e8]
          // 7:  00
          memory_copy(&code[pos], "\x48\x8b\x84\x24", 4);
          pos += 4;
          memory_copy(&code[pos], &reg, 4);
          pos += 4;
          // 1a: 48 83 c0 02             add    rax,0x2
          memory_copy(&code[pos], "\x48\x83\xc0\x02", 4);
          pos += 4;
          //a:  48 89 84 24 e8 03 00    mov    QWORD PTR [rsp+0x3e8],rax
          //11: 00
          memory_copy(&code[pos], "\x48\x89\x84\x24", 4);
          pos += 4;
          memory_copy(&code[pos], &reg, 4);
          pos += 4;
        }
        {
          i8 reg = 8 * GET_INTEGER(NTH(a, 2));
          //1a: 48 3b 84 24 e8 03 00    cmp    rax,QWORD PTR [rsp+0x3e8]
          //21: 00
          memory_copy(&code[pos], "\x48\x3b\x84\x24", 4);
          pos += 4;
          memory_copy(&code[pos], &reg, 4);
          pos += 4;
        }
        // 26: 0f 82 e8 03 00 00       jb     414 <test+0x3e8>
        memory_copy(&code[pos], "\x0f\x82\x00\x00\x00\x00", 6);
        pos += 6;

        VEC_PUSHBACK(u8, fix_labels, GET_INTEGER(NTH(a, 3))); /* label num */
        VEC_PUSHBACK(u8, fix_labels, pos - 4); /* write pos */
        VEC_PUSHBACK(u8, fix_labels, pos); /* offset calculation base */
      }
      else
      {
        FMT(STDERR_H, "Unknown instruction:");
        print_object(STDERR_H, sym);
        FMT(STDERR_H, "\n");
        return -1;
      }
    }
  }

  FMT(STDOUT_H, "Fixing jump offsets...\n");

  for (i8 i = 0; i < VEC_SIZE(u8, fix_labels); i += 3)
  {
    i8 label_num = VEC_NTH(u8, fix_labels, i);
    i8 write_pos = VEC_NTH(u8, fix_labels, i + 1);
    i8 offset_origin = VEC_NTH(u8, fix_labels, i + 2);

    i8 label_pos =  VEC_SIZE(u8, label_positions) > label_num ? VEC_NTH(u8, label_positions, label_num) : -1;

    if (label_pos >= 0)
    {
      i8 offset = label_pos - offset_origin;
      FMT(STDOUT_H, "Label %lld is at pos %lld; write jump offset at pos %lld: %lld (* 8 bytes) (offset origin %lld)\n",
          label_num, label_pos, write_pos, offset, offset_origin);
      memory_copy(&cs->machinecode[write_pos], &offset , 4);
    }
    else
    {
      FMT(STDOUT_H, "Label %lld undefined (but referenced)\n", label_num);
    }
  }

  cs->machinecodepos = pos;

  VEC_FREE(fix_labels);
  VEC_FREE(label_positions);
  return 0;
}
#endif

obj generate_symbol(interpreter_t *interp, compiler_state *cs)
{
  i1 str[40];
  SNPRINTF(str, sizeof(str), "_gs_%llu", ATOMIC_ADD_AND_FETCH64(&cs->gensym_counter, 1) - 1);
  return make_symbol(interp, str);
}

u0 add_lexical_variable(compiler_state *cs, obj symbol, i8 idx)
{
  cs->lexical_vars[cs->lexical_vars_pos].sym = symbol;
  cs->lexical_vars[cs->lexical_vars_pos].var_idx = idx;
  cs->lexical_vars_pos++;
}

i8 find_lexical_variable_pos(compiler_state *cs, obj symbol)
{
  for (i8 i = cs->lexical_vars_pos - 1; i >= 0; i--)
  {
    if (symbol == cs->lexical_vars[i].sym)
    {
      return i;
    }
  }

  return -1;
}

i8 find_lexical_variable_idx(compiler_state *cs, obj symbol)
{
  for (i8 i = cs->lexical_vars_pos - 1; i >= 0; i--)
  {
    if (symbol == cs->lexical_vars[i].sym)
    {
      return cs->lexical_vars[i].var_idx;
    }
  }

  return -1;
}

u0 push_lexical_scope(compiler_state *cs)
{
  cs->lexical_frames[cs->lexical_frames_pos++] = cs->lexical_vars_pos;
}

u0 pop_lexical_scope(compiler_state *cs)
{
  if (cs->lexical_frames_pos > 0)
  {
    cs->lexical_vars_pos = cs->lexical_frames[--cs->lexical_frames_pos];
  }
}

u0 push_loop(compiler_state *cs, i8 start_label, i8 end_label)
{
  cs->loops[cs->loops_pos][0] = start_label;
  cs->loops[cs->loops_pos][1] = end_label;
  cs->loops_pos++;
}

u0 pop_loop(compiler_state *cs)
{
  if (cs->loops_pos > 0)
  {
    --cs->loops_pos;
  }
}

i8 get_label_idx(compiler_state *cs)
{
  return cs->label_counter++;
}

#if 0
i8 add_global_function_value(globals_t *glob, obj symbol, obj value, i1 is_const)
{
  i8 idx = -1;
  for (i8 i = 0; i < glob->count; i++)
  {
    if (glob->symbol[i] == symbol)
    {
      WARN("Redefining global variable: %s", get_symbol_string(symbol));
      idx = i;
      break;
    }
  }

  if (idx == -1)
  {
    idx = glob->count;
    glob->symbol[idx] = symbol;
    glob->count++;
  }
  glob->function_value[idx] = value;
  glob->is_function_value_const[idx] = is_const;
  return 0;
}

i8 add_global_variable(globals_t *glob, obj symbol, obj value, i1 is_const)
{
  for (i8 i = 0; i < glob->count; i++)
  {
    if (glob->symbol[i] == symbol)
    {
      WARN("Redefining global variable: %s", get_symbol_string(symbol));
      return -1;
    }
  }

  glob->symbol[glob->count] = symbol;
  glob->value[glob->count] = value;
  glob->is_const[glob->count] = is_const;
  glob->count++;
  return 0;
}
#endif

i8 find_global_variable(compiler_state *cs, obj symbol)
{
#if 1
  symbol_t *syb = GET_SYMBOL(symbol);

  if (syb->flags & SF_HAS_VALUE)
    return 0;

  return -1;
#else
  globals_t *glob = cs->glob;
  for (i8 i = 0; i < glob->count; i++)
  {
    if (glob->symbol[i] == symbol)
    {
      return i;
    }
  }

  return -1;
#endif
}

i8 new_variable(compiler_state *cs, i8 kind, i8 var_sequence_number, obj sym, i1 is_const, obj value)
{
  i8 i = cs->vars_count;
  cs->vars[i].kind = kind;
  cs->vars[i].var_sequence_number = var_sequence_number;
  cs->vars[i].sym = sym;
  cs->vars[i].is_const = is_const;
  cs->vars[i].value = value;
  cs->vars[i].stack_pos = -1;

  return cs->vars_count++;
}

i8 allocate_temporary_variable(compiler_state *cs)
{
  return new_variable(cs, VAR_TEMPORARY, -1, NONE_VALUE, 0, NONE_VALUE);
}

i8 find_or_allocate_call_argument(compiler_state *cs, i8 var_sequence_number)
{
  for (i8 i = 0; i < cs->vars_count; i++)
  {
    if (cs->vars[i].kind == VAR_CALL_ARGUMENT && cs->vars[i].var_sequence_number == var_sequence_number)
      return i;
  }

  return new_variable(cs, VAR_CALL_ARGUMENT, var_sequence_number, NONE_VALUE, 0, NONE_VALUE);
}

i8 result_to_variable(interpreter_t *interp, compiler_state *cs, obj code_list, compile_result *cr)
{
  switch (cr->type)
  {
    case CR_ERROR:
    default:
      break;
    case CR_IMMEDIATE:
      {
        i8 var_idx = allocate_temporary_variable(cs);
        array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moveri, MAKE_INTEGER(var_idx), INC(interp, cr->immediate_val)));
        cr->type = CR_VARIABLE;
        cr->var_idx = var_idx;
        return var_idx;
      }
      break;
    case CR_VARIABLE:
      return cr->var_idx;
      break;
    case CR_CONDITION:
      break;
  }

  return -1;
}

obj macroexpand_for(interpreter_t *interp, obj o, compiler_state *cs)
{
  obj iterator = NTH(o, 1);
  obj var = NTH(iterator, 0);
  obj start_lim = ASIZE(iterator) > 2 ? NTH(iterator, 1) : MAKE_INTEGER(0);
  obj max_lim = ASIZE(iterator) > 2 ? NTH(iterator, 2) : NTH(iterator, 1);

  obj max_lim_sym = generate_symbol(interp, cs);

  obj ret = make_array(interp, 3, interp->s_do, make_array(interp, 3, interp->s_let, var, INC(interp, start_lim)), make_array(interp, 3, interp->s_let, max_lim_sym, INC(interp, max_lim)));

  obj loop_obj = make_array(interp, 1, interp->s_with_loop);
  array_add_obj(interp, ret, make_array(interp, 3, interp->s_if, make_array(interp, 3, interp->s_lt, var, max_lim_sym), loop_obj));

  obj expressions = array_copy(interp, o, 2);

  array_append(interp, loop_obj, expressions, 1);

  DEC(interp, expressions);

#if 0
  array_add_obj(interp, loop_obj, make_array(interp, 3, interp->s_inc, var, MAKE_INTEGER(1)));
  array_add_obj(interp, loop_obj, make_array(interp, 3, interp->s_if, make_array(interp, 3, interp->s_lt, var, max_lim_sym), make_array(interp, 1, interp->s_next_loop)));
#else
  array_add_obj(interp, loop_obj, make_array(interp, 3, interp->s_inc_jump_lt, var, max_lim_sym));
#endif

  return ret;
}

#define PRINT_ERROR_TO_STR(out, o, ...) do { i1 tmp[124]; i1 tmp2[124]; SNPRINTF(tmp, sizeof(tmp), __VA_ARGS__); \
  print_object_string(tmp2, sizeof(tmp2), o); SNPRINTF(out, sizeof(out), "Compile error: %s: %s\n", tmp, tmp2); } while(0)

#define COMPILE_ERROR(o, resultcr, ...) do { FMT(STDERR_H, "Compile error: "); FMT(STDERR_H, __VA_ARGS__); FMT(STDERR_H, ": "); \
  print_object(STDERR_H, (o)); FMT(STDERR_H, "\n"); (resultcr)->type = CR_ERROR; PRINT_ERROR_TO_STR((resultcr)->str, o, __VA_ARGS__); return *(resultcr); } while(0)
#define COMPILE_CHECK_NUM_ARGS(o, resultcr, min_args, max_args) do { \
  if (ASIZE((o)) < ((min_args) + 1)) COMPILE_ERROR(o, resultcr, "Too few arguments (minimum %d)", min_args); \
  if (max_args >= 0 && ASIZE((o)) > ((max_args) + 1)) COMPILE_ERROR(o, resultcr, "Too many arguments (maximum %d)", max_args); } while(0)
#define PROPAGATE_COMPILE_ERROR(o, crptr, resultcr) do { \
  if ((crptr)->type == CR_ERROR) { FMT(STDERR_H, "While compiling: "); print_object(STDERR_H, (o)); FMT(STDERR_H, "\n"); (resultcr)->type = CR_ERROR; str_copy((resultcr)->str, (crptr)->str); return *(resultcr); } \
} while(0)

/**
 * Check if there is an immediate unconditional jump in the code and return its label
 * Used to simplify 'if' jumps (jump directly to target).
 */
i8 check_jump(interpreter_t *interp, obj code, i8 *jump_label)
{
  if (IS_OBJ_ARRAY(code))
  {
    for (i8 i = 0; i < ASIZE(code); i++)
    {
      obj o = NTH(code, i);

      if (IS_OBJ_ARRAY(o) && NTH(o, 0) == interp->s_jump)
      {
        /* found the jump */
        if (jump_label)
          *jump_label = GET_INTEGER(NTH(o, 1));

        // FMT(STDOUT_H, "Found jump to label %lld\n", GET_INTEGER(NTH(o, 1)));
        // FMT(STDOUT_H, "In: "); print_object(code); FMT(STDOUT_H, "\n");
        return 1;
      }

      /* allow only label statements in between */
      if (!(IS_OBJ_ARRAY(o) && NTH(o, 0) == interp->s_label))
        break;
    }
  }

  return 0;
}

obj compile_function(interpreter_t *interp, obj o, compiler_state *cs_outer, compile_result *cr_out);
compile_result compile_expression(interpreter_t *interp, obj o, compiler_state *cs, obj code_list, i1 keep_result, i8 result_var_idx, i8 comparison_flags, i8 force_variable_result);

compile_result compile_list(interpreter_t *interp, obj o, compiler_state *cs, obj code_list, i8 offset, i1 keep_result, i8 result_var_idx)
{
  compile_result cr;
  cr.type = CR_IMMEDIATE;
  cr.immediate_val = NONE_VALUE;
  i8 contains_function_call = 0;

  if (IS_OBJ_ARRAY(o))
  {
    for (i8 i = offset; i < ASIZE(o); i++)
    {
      /* keep last element ? */
      i8 keep_result2 = (keep_result && (i == (ASIZE(o) - 1))) ? 1 : 0;
      compile_result cr_arg = compile_expression(interp, NTH(o, i), cs, code_list, keep_result2, keep_result2 ? result_var_idx : -1, 0, keep_result2 ? 1 : 0);
      PROPAGATE_COMPILE_ERROR(o, &cr_arg, &cr);
      contains_function_call |= cr_arg.contains_function_call;
      if (keep_result2)
        cr = cr_arg;
    }
  }

  cr.contains_function_call = contains_function_call;
  return cr;
}

i8 get_variable_lexical_or_global(interpreter_t *interp, obj var_sym, compiler_state *cs, obj code_list)
{
  i8 store_var_idx = find_lexical_variable_idx(cs, var_sym);
  if (store_var_idx >= 0)
  {
    return store_var_idx;
  }
  else
  {
    i8 idx = find_global_variable(cs, var_sym);
    if (idx >= 0)
    {
      //i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
      i8 var_idx = allocate_temporary_variable(cs);

      array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moverglobal, MAKE_INTEGER(var_idx), var_sym));
      return var_idx;
    }
    else
    {
      return -1;
    }
  }
}

u0 update_constants(interpreter_t *interp, obj value, obj sym, i8 *constants, f8 *constants_real, i8 *promoted_to_real)
{
  if (IS_INTEGER(value))
  {
    if (*promoted_to_real == 0)
    {
      if (sym == interp->s_plus)
        *constants += GET_INTEGER(value);
      else if (sym == interp->s_times)
        *constants *= GET_INTEGER(value);
      else if (sym == interp->s_minus)
        *constants -= GET_INTEGER(value);
      else if (sym == interp->s_divide)
      {
        *constants_real = (f8)*constants;
        *promoted_to_real = 1;
        *constants_real /= GET_INTEGER(value);
      }
    }
    else
    {
      if (sym == interp->s_plus)
        *constants_real += GET_INTEGER(value);
      else if (sym == interp->s_times)
        *constants_real *= GET_INTEGER(value);
      else if (sym == interp->s_minus)
        *constants_real -= GET_INTEGER(value);
      else if (sym == interp->s_divide)
      {
        if (GET_INTEGER(value) != 0)
          *constants_real /= GET_INTEGER(value);
      }
    }
  }
  else if (IS_REAL(value))
  {
    if (*promoted_to_real == 0)
    {
      *constants_real = (f8)*constants;
      *promoted_to_real = 1;
    }
    if (sym == interp->s_plus)
      *constants_real += TO_F8(value);
    else if (sym == interp->s_times)
      *constants_real *= TO_F8(value);
    else if (sym == interp->s_minus)
      *constants_real -= TO_F8(value);
    else if (sym == interp->s_divide)
    {
      if (TO_F8(value) != 0)
        *constants_real /= TO_F8(value);
    }
  }
}

i1 symbol_has_function_value(obj sym)
{
  if (IS_SYMBOL(sym))
  {
    symbol_t* sym_object = GET_SYMBOL(sym);
    return !!(sym_object->flags & SF_HAS_FUNCTION_VALUE);
  }
  return 0;
}

compile_result compile_expression(interpreter_t *interp, obj o, compiler_state *cs, obj code_list, i1 keep_result, i8 result_var_idx, i8 comparison_flags, i8 force_variable_result)
{
  // if keep_result == 0 don't emit code for propagating the result value (allocation of a temporary variable etc.), because
  // result is not needed in the context of the expression
  compile_result cr;
  cr.type = CR_NONE;
  cr.contains_function_call = 0;
  i8 contains_function_call = 0;

  // FMT(STDOUT_H, "Compile (keep result %d result var idx %lld): ", keep_result, result_var_idx); print_object(STDOUT_H, o); FMT(STDOUT_H, "\n");

  if (IS_NONE(o) || IS_INTEGER(o) || IS_REAL(o))
  {
    cr.type = CR_IMMEDIATE;
    cr.immediate_val = o;
  }
  else if (IS_STRING(o))
  {
    cr.type = CR_IMMEDIATE;
    cr.immediate_val = o;
  }
  else if (IS_SYMBOL(o))
  {
    /* lookup variables */
    i8 var_idx = find_lexical_variable_idx(cs, o);
    if (var_idx >= 0)
    {
      if (keep_result)
      {
        cr.type = CR_VARIABLE;
        cr.var_idx = var_idx;
      }
      goto do_return;
    }
    else
    {
      i8 idx = find_global_variable(cs, o);
      if (idx >= 0)
      {
        if (keep_result)
        {
          i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
          array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moverglobal, MAKE_INTEGER(var_idx), o));
          cr.type = CR_VARIABLE;
          cr.var_idx = var_idx;
        }
        goto do_return;
      }
      else
      {
        COMPILE_ERROR(o, &cr, "Variable not found");
      }
    }
  }
  else if (IS_OBJ_ARRAY(o))
  {
    if (ASIZE(o) == 0)
    {
      /* empty vector */
      COMPILE_ERROR(o, &cr, "Empty list");
    }
    else
    {
      obj sym = NTH(o, 0);
      if (!IS_SYMBOL(sym))
      {
        COMPILE_ERROR(o, &cr, "First element must be a symbol");
      }

      //FMT(STDOUT_H, ".\n");
      if (sym == interp->s_comment)
      {
        cr.type = CR_IMMEDIATE;
        cr.immediate_val = NONE_VALUE;
      }
      else if (sym == interp->s_quote)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 1, 1);
        cr.type = CR_IMMEDIATE;
        cr.immediate_val = INC(interp, NTH(o, 1));
      }
      else if (sym == interp->s_do)
      {
        /* emit code, returning last result */
        push_lexical_scope(cs);

        cr = compile_list(interp, o, cs, code_list, 1, keep_result, result_var_idx);
        contains_function_call |= cr.contains_function_call;

        /* code for decrefing lexical variables */
        for (i8 i = cs->lexical_vars_pos - 1; i >= cs->lexical_frames[cs->lexical_frames_pos - 1]; i--)
        {
          i8 var_idx = cs->lexical_vars[i].var_idx;
          if (cr.type != CR_VARIABLE || cr.var_idx != var_idx) /* if variable is not used as a return value */
          {
            array_add_obj(interp, code_list, make_array(interp, 2, interp->s_decref, MAKE_INTEGER(var_idx)));
          }
          else
            PRINT_ERROR("Unexpected - lexical variable is returned as a return value\n");
        }
        pop_lexical_scope(cs);
      }
      else if (sym == interp->s_let)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 1, -1);
        /* defining local variables */
        obj sym = NTH(o, 1);
        obj value = NTH(o, 2);

        i8 var_idx = new_variable(cs, VAR_LEXICAL, 0, sym, 0, NONE_VALUE);
        compile_result cr_arg1 = compile_expression(interp, value, cs, code_list, 1, var_idx, 0, 1);
        PROPAGATE_COMPILE_ERROR(o, &cr_arg1, &cr);
        contains_function_call |= cr_arg1.contains_function_call;
        add_lexical_variable(cs, sym, var_idx);

        if (keep_result)
        {
          i8 ret_var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
          array_add_obj(interp, code_list, make_array(interp, 2, interp->s_incref, MAKE_INTEGER(var_idx)));
          array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moverr, MAKE_INTEGER(ret_var_idx), MAKE_INTEGER(var_idx)));
          cr.type = CR_VARIABLE;
          cr.var_idx = ret_var_idx;
        }

        goto do_return;
      }
      else if (sym == interp->s_if)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 2, 3);

        obj condition = NTH(o, 1);
        obj then_expr = NTH(o, 2);
        obj else_expr = ASIZE(o) > 3 ? NTH(o, 3) : NONE_VALUE; /* if if has only 3 elements it's equivalent to else = None if */

        push_lexical_scope(cs);

        compile_result cr_arg0 = compile_expression(interp, condition, cs, code_list, 1, -1, 1, 0);
        PROPAGATE_COMPILE_ERROR(o, &cr_arg0, &cr);
        contains_function_call |= cr_arg0.contains_function_call;

        i8 else_label = get_label_idx(cs);
        i8 end_label = get_label_idx(cs);

        obj then_code = make_array(interp, 0);
        obj else_code = make_array(interp, 0);

        i8 ret_var_idx = keep_result ? (result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs)) : -1;

        compile_result cr3 = compile_expression(interp, then_expr, cs, then_code, keep_result, ret_var_idx, 0, 1);
        PROPAGATE_COMPILE_ERROR(o, &cr3, &cr);
        contains_function_call |= cr3.contains_function_call;

        compile_result cr4 = compile_expression(interp, else_expr, cs, else_code, keep_result, ret_var_idx, 0, 1);
        PROPAGATE_COMPILE_ERROR(o, &cr4, &cr);
        contains_function_call |= cr4.contains_function_call;

        /* optimize jump depending on any unconditional jump in then/else code - jump only once */

        i8 jump_label = else_label;
        i8 reverse_check = 1;
        i8 has_jump = check_jump(interp, else_code, &jump_label) ? 2 : (check_jump(interp, then_code, &jump_label) ? 1 : 0);
        if (has_jump == 1)
        {
          /* if we want then-jump */
          reverse_check = 0;
        }

        /* include the jump into the condition jump if possible */
        if (cr_arg0.type == CR_CONDITION)
        {
          obj cond_symbol = NONE_VALUE;
          if (cr_arg0.condition < C_MIN || cr_arg0.condition >= C_MAX)
            COMPILE_ERROR(o, &cr, "Uknown condition value");

          if (reverse_check)
            cond_symbol = SYMBOL_OBJ(interp, conditional_jump_sym[condition_negation[cr_arg0.condition]]);
          else
            cond_symbol = SYMBOL_OBJ(interp, conditional_jump_sym[cr_arg0.condition]);

          array_add_obj(interp, code_list, make_array(interp, 3, interp->s_cmprr, MAKE_INTEGER(cr_arg0.condition_var_idx1), MAKE_INTEGER(cr_arg0.condition_var_idx2)));
          array_add_obj(interp, code_list, make_array(interp, 2, cond_symbol, MAKE_INTEGER(jump_label)));
        }
        else
        {
          i8 var_idx = result_to_variable(interp, cs, code_list, &cr_arg0);
          array_add_obj(interp, code_list, make_array(interp, 3, interp->s_cmpri, MAKE_INTEGER(var_idx), NONE_VALUE));
          array_add_obj(interp, code_list, make_array(interp, 2, reverse_check ? interp->s_jump_eq : interp->s_jump_ne, MAKE_INTEGER(jump_label)));
        }


        if (has_jump != 1) /* if then clause was not absorbed into the first jump */
        {
          array_append(interp, code_list, then_code, 1);

          if (has_jump == 0) /* if else clause was not absorbed into the first jump */
            array_add_obj(interp, code_list, make_array(interp, 2, interp->s_jump, MAKE_INTEGER(end_label)));
        }

        if (has_jump != 2) /* if else clause was not absorbed into the first jump */
        {
          if (has_jump == 0)
            array_add_obj(interp, code_list, make_array(interp, 2, interp->s_label, MAKE_INTEGER(else_label)));
          array_append(interp, code_list, else_code, 1);
        }

        if (has_jump == 0)
          array_add_obj(interp, code_list, make_array(interp, 2, interp->s_label, MAKE_INTEGER(end_label)));

        DEC(interp, then_code);
        DEC(interp, else_code);

        if (keep_result)
        {
          cr.type = CR_VARIABLE;
          cr.var_idx = ret_var_idx;
        }

        /* code for decrefing lexical variables */
        for (i8 i = cs->lexical_vars_pos - 1; i >= cs->lexical_frames[cs->lexical_frames_pos - 1]; i--)
        {
          i8 var_idx = cs->lexical_vars[i].var_idx;
          if (cr.type != CR_VARIABLE || cr.var_idx != var_idx) /* if variable is not used as a return value */
          {
            array_add_obj(interp, code_list, make_array(interp, 2, interp->s_decref, MAKE_INTEGER(var_idx)));
          }
          else
            PRINT_ERROR("Unexpected - lexical variable is returned as a return value\n");
        }
        pop_lexical_scope(cs);

        goto do_return;
      }
      else if (sym == interp->s_aindex)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 2, 2);
        /* return element of array at index */
        obj var_sym = NTH(o, 1);
        obj value = NTH(o, 2);

        if (!IS_SYMBOL(var_sym))
        {
          COMPILE_ERROR(o, &cr, "First argument should be a symbol");
        }

        compile_result cr_arg1 = compile_expression(interp, value, cs, code_list, 1, -1, 0, 0);
        PROPAGATE_COMPILE_ERROR(o, &cr_arg1, &cr);
        contains_function_call |= cr_arg1.contains_function_call;

        i8 var_idx = find_lexical_variable_idx(cs, var_sym);
        if (var_idx >= 0)
        {
        }
        else
        {
          i8 idx = find_global_variable(cs, var_sym);
          if (idx >= 0)
          {
            var_idx = allocate_temporary_variable(cs);
            array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moverglobal, MAKE_INTEGER(var_idx), var_sym));
          }
          else
          {
            COMPILE_ERROR(var_sym, &cr, "Variable not found");
          }
        }

        if (cr_arg1.type == CR_IMMEDIATE)
        {
          if (!IS_INTEGER(cr_arg1.immediate_val))
          {
            COMPILE_ERROR(o, &cr, "Only integers can be used for indexing");
          }

          i8 ret_var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
          array_add_obj(interp, code_list, make_array(interp, 4, interp->s_aindexi, MAKE_INTEGER(var_idx), cr_arg1.immediate_val, MAKE_INTEGER(ret_var_idx)));
          cr.type = CR_VARIABLE;
          cr.var_idx = ret_var_idx;
        }
        else
        {
          i8 ret_var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
          array_add_obj(interp, code_list, make_array(interp, 4, interp->s_aindexr, MAKE_INTEGER(var_idx), MAKE_INTEGER(cr_arg1.var_idx), MAKE_INTEGER(ret_var_idx)));
          cr.type = CR_VARIABLE;
          cr.var_idx = ret_var_idx;
        }
      }
      else if (sym == interp->s_set)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 2, -1);
        obj var_sym = NTH(o, 1);
        obj value = NTH(o, 2);

        if (IS_OBJ_ARRAY(var_sym) && NTH(var_sym, 0) == interp->s_aindex)
        {
          obj var_arr_idx = NTH(var_sym, 2);
          obj var_sym2 = NTH(var_sym, 1);
          /* array assignment */
          i8 var_idx_value = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
          compile_result cr_arg1 = compile_expression(interp, value, cs, code_list, 1, var_idx_value, 0, 1);
          PROPAGATE_COMPILE_ERROR(o, &cr_arg1, &cr);
          contains_function_call |= cr_arg1.contains_function_call;

          compile_result cr_arg2 = compile_expression(interp, var_arr_idx, cs, code_list, 1, -1, 0, 0);
          PROPAGATE_COMPILE_ERROR(o, &cr_arg2, &cr);
          contains_function_call |= cr_arg2.contains_function_call;
          i8 var_idx_index = result_to_variable(interp, cs, code_list, &cr_arg2);
          /* index expression */

          i8 var_idx_array = get_variable_lexical_or_global(interp, var_sym2, cs, code_list);
          if (var_idx_array < 0)
          {
            COMPILE_ERROR(var_sym2, &cr, "Variable not found");
          }
          array_add_obj(interp, code_list, make_array(interp, 4, interp->s_saindexr, MAKE_INTEGER(var_idx_array), MAKE_INTEGER(var_idx_index), MAKE_INTEGER(var_idx_value)));

          if (keep_result)
          {
            // TODO reference counting
            cr.type = CR_VARIABLE;
            cr.var_idx = var_idx_value; // TODO can point to lexical variable, a number shouldn't be modified by inc/etc. but object should be modified (vector or string)
          }
        }
        else
        {
          /* lookup variables */
          i8 store_var_idx = find_lexical_variable_idx(cs, var_sym);
          if (store_var_idx >= 0)
          {
            /* decref previous value TODO check if it can be skipped */
            array_add_obj(interp, code_list, make_array(interp, 2, interp->s_decref, MAKE_INTEGER(store_var_idx)));

            compile_result cr_arg1 = compile_expression(interp, value, cs, code_list, 1, store_var_idx, 0, 1);
            PROPAGATE_COMPILE_ERROR(o, &cr_arg1, &cr);
            contains_function_call |= cr_arg1.contains_function_call;

            if (keep_result)
            {
              array_add_obj(interp, code_list, make_array(interp, 2, interp->s_incref, MAKE_INTEGER(store_var_idx)));
              i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
              array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moverr, MAKE_INTEGER(var_idx), MAKE_INTEGER(store_var_idx)));

              cr.type = CR_VARIABLE;
              cr.var_idx = var_idx; // TODO can point to lexical variable, a number shouldn't be modified by inc/etc. but object should be modified (vector or string)
            }
            goto do_return;
          }
          else
          {
            i8 idx = find_global_variable(cs, var_sym);
            if (idx >= 0)
            {
              i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
              compile_result cr_arg1 = compile_expression(interp, value, cs, code_list, 1, var_idx, 0, 1);
              PROPAGATE_COMPILE_ERROR(o, &cr_arg1, &cr);
              contains_function_call |= cr_arg1.contains_function_call;

              if (keep_result)
              {
                /* need to incref the value if it is used also as a result */
                array_add_obj(interp, code_list, make_array(interp, 2, interp->s_incref, MAKE_INTEGER(var_idx)));
                cr.type = CR_VARIABLE;
                cr.var_idx = var_idx;
              }

              array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moveglobalr, var_sym, MAKE_INTEGER(var_idx)));
              goto do_return;
            }
            else
            {
              COMPILE_ERROR(var_sym, &cr, "Variable not found");
            }
          }
        }
      }
      else if (sym == interp->s_define)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 1, -1);
        /* defining global variable / function */
        obj var_sym = NTH(o, 1);
        obj value = (ASIZE(o) > 2) ? NTH(o, 2) : NONE_VALUE;

        if (IS_OBJ_ARRAY(var_sym))
        {
          obj func_sym = NTH(var_sym, 0);
          cr.type = CR_IMMEDIATE;
          compile_result cr_func;
          cr_func.type = CR_NONE;
          cr.immediate_val = compile_function(interp, o, cs, &cr_func);
          PROPAGATE_COMPILE_ERROR(o, &cr_func, &cr);
          // add_global_function_value(cs->glob, func_sym, cr.immediate_val, 0);
          /* should return a function? */
          // code for binding the function to a symbol (insert into main code)
          array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moveglobalfuni, func_sym, INC(interp, cr.immediate_val)));
          goto do_return;
        }
        else
        {
          COMPILE_CHECK_NUM_ARGS(o, &cr, 1, 2);
          // add_global_variable(cs->glob, var_sym, value, 0);
          /* emit code */
          i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
          compile_result cr_arg1 = compile_expression(interp, value, cs, code_list, 1, var_idx, 0, 1);
          PROPAGATE_COMPILE_ERROR(o, &cr_arg1, &cr);
          contains_function_call |= cr_arg1.contains_function_call;
          if (keep_result)
          {
            /* need to incref the value if it is used also as a result */
            array_add_obj(interp, code_list, make_array(interp, 2, interp->s_incref, MAKE_INTEGER(var_idx)));
          }
          array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moveglobalr, var_sym, MAKE_INTEGER(var_idx)));

          if (keep_result)
          {
            cr.type = CR_VARIABLE;
            cr.var_idx = var_idx;
          }
          goto do_return;
        }
      }
      else if (sym == interp->s_eq || sym == interp->s_ne || sym == interp->s_gt || sym == interp->s_lt || sym == interp->s_ge || sym == interp->s_le)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 2, 2);
        obj expr1 = NTH(o, 1);
        obj expr2 = NTH(o, 2);

        compile_result cr_arg0 = compile_expression(interp, expr1, cs, code_list, 1, -1, 0, 0);
        PROPAGATE_COMPILE_ERROR(o, &cr_arg0, &cr);
        contains_function_call |= cr_arg0.contains_function_call;
        i8 var_idx1 = result_to_variable(interp, cs, code_list, &cr_arg0);

        {
          compile_result cr3 = compile_expression(interp, expr2, cs, code_list, 1, -1, 0, 0);
          PROPAGATE_COMPILE_ERROR(o, &cr3, &cr);
          contains_function_call |= cr3.contains_function_call;
          i8 var_idx2 = result_to_variable(interp, cs, code_list, &cr3);

          if (comparison_flags)
          {
            cr.type = CR_CONDITION;
            cr.condition_var_idx1 = var_idx1;
            cr.condition_var_idx2 = var_idx2;

            if (sym == interp->s_eq)
              cr.condition = C_EQ;
            else if (sym == interp->s_ne)
              cr.condition = C_NE;
            else if (sym == interp->s_gt)
              cr.condition = C_GT;
            else if (sym == interp->s_lt)
              cr.condition = C_LT;
            else if (sym == interp->s_ge)
              cr.condition = C_GE;
            else if (sym == interp->s_le)
              cr.condition = C_LE;
          }
          else
          {
            if (keep_result)
            {
              i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
              /* construct an if */

              i8 else_label = get_label_idx(cs);
              i8 end_label = get_label_idx(cs);

              i8 condition = C_EQ;
              obj cond_symbol = NONE_VALUE;
              if (sym == interp->s_eq)
                condition = C_EQ;
              else if (sym == interp->s_ne)
                condition = C_NE;
              else if (sym == interp->s_gt)
                condition = C_GT;
              else if (sym == interp->s_lt)
                condition = C_LT;
              else if (sym == interp->s_ge)
                condition = C_GE;
              else if (sym == interp->s_le)
                condition = C_LE;

              cond_symbol = SYMBOL_OBJ(interp, conditional_jump_sym[condition]);

              array_add_obj(interp, code_list, make_array(interp, 3, interp->s_cmprr, MAKE_INTEGER(var_idx1), MAKE_INTEGER(var_idx2)));

              array_add_obj(interp, code_list, make_array(interp, 2, cond_symbol, MAKE_INTEGER(else_label)));

              array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moveri, MAKE_INTEGER(var_idx), INC(interp, NONE_VALUE)));
              array_add_obj(interp, code_list, make_array(interp, 2, interp->s_jump, MAKE_INTEGER(end_label)));

              array_add_obj(interp, code_list, make_array(interp, 2, interp->s_label, MAKE_INTEGER(else_label)));
              array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moveri, MAKE_INTEGER(var_idx), INC(interp, MAKE_INTEGER(1))));

              array_add_obj(interp, code_list, make_array(interp, 2, interp->s_label, MAKE_INTEGER(end_label)));

              cr.type = CR_VARIABLE;
              cr.var_idx = var_idx;
            }
          }
        }
      }
      else if (sym == interp->s_with_loop)
      {
        i8 loop_start_label = get_label_idx(cs);
        i8 loop_end_label = get_label_idx(cs);

        push_lexical_scope(cs);

        push_loop(cs, loop_start_label, loop_end_label);
        array_add_obj(interp, code_list, make_array(interp, 2, interp->s_label, MAKE_INTEGER(loop_start_label)));

        /* emit code */
        cr = compile_list(interp, o, cs, code_list, 1, 0 /*keep_result*/, -1 /* result_var_idx */);
        contains_function_call |= cr.contains_function_call;

        pop_loop(cs);
        array_add_obj(interp, code_list, make_array(interp, 2, interp->s_label, MAKE_INTEGER(loop_end_label)));

        if (keep_result)
        {
          cr.type = CR_IMMEDIATE;
          cr.immediate_val = NONE_VALUE;
        }

        /* code for decrefing lexical variables */
        for (i8 i = cs->lexical_vars_pos - 1; i >= cs->lexical_frames[cs->lexical_frames_pos - 1]; i--)
        {
          i8 var_idx = cs->lexical_vars[i].var_idx;
          if (cr.type != CR_VARIABLE || cr.var_idx != var_idx) /* if variable is not used as a return value */
          {
            array_add_obj(interp, code_list, make_array(interp, 2, interp->s_decref, MAKE_INTEGER(var_idx)));
          }
          else
            PRINT_ERROR("Unexpected - lexical variable is returned as a return value\n");
        }
        pop_lexical_scope(cs);
      }
      else if (sym == interp->s_next_loop)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 0, 0);

        if (cs->loops_pos > 0)
        {
          array_add_obj(interp, code_list, make_array(interp, 2, interp->s_jump, MAKE_INTEGER(cs->loops[cs->loops_pos - 1][0])));
        }
        else
        {
          COMPILE_ERROR(o, &cr, "Can't use jump-loop outside a loop");
        }
      }
      else if (sym == interp->s_inc_jump_lt)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 2, 2);
        obj var = NTH(o, 1);
        obj limit_var = NTH(o, 2);

        i8 var_idx = find_lexical_variable_idx(cs, var);
        i8 limit_var_idx = find_lexical_variable_idx(cs, limit_var);

        if (var_idx < 0 || limit_var_idx < 0)
          COMPILE_ERROR(o, &cr, "Variables expected");

        if (cs->loops_pos > 0)
        {
          i8 loop_start_label = cs->loops[cs->loops_pos - 1][0];

          array_add_obj(interp, code_list, make_array(interp, 4, interp->s_inc_jump_lt, MAKE_INTEGER(var_idx), MAKE_INTEGER(limit_var_idx), MAKE_INTEGER(loop_start_label)));
        }
        else
        {
          COMPILE_ERROR(o, &cr, "Can't use jump-loop outside a loop");
        }
      }
      else if (sym == interp->s_for)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 1, -1);
        obj o_expanded = macroexpand_for(interp, o, cs);
        FMT(STDOUT_H, "After macroexpand:\n");
        print_object(STDOUT_H, o_expanded);
        FMT(STDOUT_H, "\n");
        array_move(interp, o, o_expanded);
        DEC(interp, o_expanded);
        cr = compile_expression(interp, o, cs, code_list, keep_result, result_var_idx, comparison_flags, force_variable_result);
        contains_function_call |= cr.contains_function_call;
      }
      else if (sym == interp->s_plus || sym == interp->s_times || sym == interp->s_minus || sym == interp->s_divide)
      {
        if (sym == interp->s_minus)
          COMPILE_CHECK_NUM_ARGS(o, &cr, 1, -1);
        if (sym == interp->s_divide)
          COMPILE_CHECK_NUM_ARGS(o, &cr, 2, -1);

        if (ASIZE(o) == 1)
        {
          cr.immediate_val = sym == (interp->s_plus || sym == interp->s_minus) ? MAKE_INTEGER(0) : MAKE_INTEGER(1);
          cr.type = CR_IMMEDIATE;
          goto do_return;
        }
        else if (ASIZE(o) == 2) /* single value */
        {
          if (sym == interp->s_minus)
          {
            cr = compile_expression(interp, NTH(o, 1), cs, code_list, 1, result_var_idx, 0, 0);
            /* do number negation */
            if (cr.type == CR_IMMEDIATE)
            {
              if (IS_INTEGER(cr.immediate_val))
                cr.immediate_val = MAKE_INTEGER(-GET_INTEGER(cr.immediate_val));
              else if (IS_REAL(cr.immediate_val))
                cr.immediate_val = MAKE_REAL(-TO_F8(cr.immediate_val));
            }
            else
            {
              if (cr.var_idx != result_var_idx && cs->vars[cr.var_idx].kind != VAR_TEMPORARY)
              {
                /* move to a temporary variable */
                i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs);
                array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moverr, MAKE_INTEGER(var_idx), MAKE_INTEGER(cr.var_idx)));
                cr.type = CR_VARIABLE;
                cr.var_idx = var_idx;
              }

              array_add_obj(interp, code_list, make_array(interp, 2, interp->s_negate, MAKE_INTEGER(cr.var_idx)));
            }
          }
          else
          {
            cr = compile_expression(interp, NTH(o, 1), cs, code_list, keep_result, result_var_idx, 0, force_variable_result);
          }
          goto do_return;
        }
        else
        {
          i8 constants = 0;
          f8 constants_real = 0.0;
          i8 promoted_to_real = 0;

          if (sym == interp->s_times || sym == interp->s_divide)
          {
            constants = 1;
            constants_real = 1.0;
          }

          obj sym_opri = interp->s_addri;
          obj sym_oprr = interp->s_addrr;

          if (sym == interp->s_minus)
          {
            sym_opri = interp->s_addri;
            sym_oprr = interp->s_subrr;
          }
          else if (sym == interp->s_times)
          {
            sym_opri = interp->s_mulri;
            sym_oprr = interp->s_mulrr;
          }
          else if (sym == interp->s_divide)
          {
            sym_opri = interp->s_mulri;
            sym_oprr = interp->s_divrr;
          }

          obj o_1 = NTH(o, 1);
          cr.type = CR_IMMEDIATE; /* start with an immediate value as the result */

          compile_result cr_arg0 = compile_expression(interp, o_1, cs, code_list, 1, result_var_idx, 0, 0);
          PROPAGATE_COMPILE_ERROR(o, &cr_arg0, &cr);
          contains_function_call |= cr_arg0.contains_function_call;

          switch (cr_arg0.type)
          {
            case CR_IMMEDIATE:
              if (IS_INTEGER(cr_arg0.immediate_val))
              {
                constants = GET_INTEGER(cr_arg0.immediate_val);
              }
              else if (IS_REAL(cr_arg0.immediate_val))
              {
                promoted_to_real = 1;
                constants_real = TO_F8(cr_arg0.immediate_val);
              }
              else
              {
                COMPILE_ERROR(o, &cr, "Only numbers allowed as an immediate value");
              }
              break;
            case CR_VARIABLE:
              {
                if (cs->vars[cr_arg0.var_idx].kind != VAR_TEMPORARY && cr_arg0.var_idx != result_var_idx)
                {
                  i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs); /* try to use result_var_idx */
                  cr.type = CR_VARIABLE;
                  cr.var_idx = var_idx;
                  array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moverr, MAKE_INTEGER(var_idx), MAKE_INTEGER(cr_arg0.var_idx)));
                }
                else
                {
                  cr.type = CR_VARIABLE;
                  cr.var_idx = cr_arg0.var_idx;
                }
              }
              break;
          }

          for (i8 i = 2; i < ASIZE(o); i++)
          {
            obj o_2 = NTH(o, i);
            /* if all values were immediate, compile with desired result in result_var_idx (but not in the case of minus and divide
             * which treat the first value differently) */
            compile_result cr_arg1 = compile_expression(interp, o_2, cs, code_list, 1, (cr.type == CR_IMMEDIATE && sym != interp->s_minus && sym != interp->s_divide) ? result_var_idx : -1, 0, 0);
            PROPAGATE_COMPILE_ERROR(o, &cr_arg1, &cr);
            contains_function_call |= cr_arg1.contains_function_call;

            switch (cr_arg1.type)
            {
              case CR_IMMEDIATE:
                if (IS_INTEGER(cr_arg1.immediate_val) || IS_REAL(cr_arg1.immediate_val))
                {
                  update_constants(interp, cr_arg1.immediate_val, sym, &constants, &constants_real, &promoted_to_real);
                }
                else
                {
                  COMPILE_ERROR(o, &cr, "Only numbers allowed as an immediate value");
                }
                break;
              case CR_VARIABLE:
                {
                  if (cr.type == CR_IMMEDIATE)
                  {
                    /* no variable up to this point */
                    if (sym == interp->s_minus || sym == interp->s_divide)
                    {
                      /* load constant into a variable */
                      //i8 var_idx = allocate_temporary_variable(cs);
                      i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs); /* try to use result_var_idx */
                      obj immediate_val = promoted_to_real ? MAKE_REAL(constants_real) : MAKE_INTEGER(constants);
                      array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moveri, MAKE_INTEGER(var_idx), INC(interp, immediate_val)));
                      constants_real = sym == interp->s_minus ? 0.0 : 1.0;
                      constants = sym == interp->s_minus ? 0 : 1;
                      cr.type = CR_VARIABLE;
                      cr.var_idx = var_idx;
                      array_add_obj(interp, code_list, make_array(interp, 3, sym_oprr, MAKE_INTEGER(cr.var_idx), MAKE_INTEGER(cr_arg1.var_idx)));
                    }
                    else
                    {
                      if (cs->vars[cr_arg1.var_idx].kind != VAR_TEMPORARY)
                      {
                        i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs); /* try to use result_var_idx */
                        cr.type = CR_VARIABLE;
                        cr.var_idx = var_idx;
                        array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moverr, MAKE_INTEGER(var_idx), MAKE_INTEGER(cr_arg1.var_idx)));
                      }
                      else
                      {
                        cr.type = CR_VARIABLE;
                        cr.var_idx = cr_arg1.var_idx; /* use the returned variable as the register where to do the additions */
                      }
                    }
                  }
                  else if (cr.type == CR_VARIABLE)
                  {
                    array_add_obj(interp, code_list, make_array(interp, 3, sym_oprr, MAKE_INTEGER(cr.var_idx), MAKE_INTEGER(cr_arg1.var_idx)));
                    /* return register is cr.var_idx */
                  }
                }
                break;
            }

            i1 is_last = (i == ASIZE(o) - 1) ? 1 : 0;

            if (is_last)
            {
              obj immediate_val = promoted_to_real ? MAKE_REAL(constants_real) : MAKE_INTEGER(constants);

              if (cr.type == CR_VARIABLE)
              {
                i8 skip_immediate = 0;
                if ((sym == interp->s_plus || sym == interp->s_minus) && ((promoted_to_real && constants_real == 0.0) || (!promoted_to_real && constants == 0)))
                  skip_immediate = 1;

                if ((sym == interp->s_times || sym == interp->s_divide) && ((promoted_to_real && constants_real == 1.0) || (!promoted_to_real && constants == 1)))
                  skip_immediate = 1;

                if (!skip_immediate)
                {
                  array_add_obj(interp, code_list, make_array(interp, 3, sym_opri, MAKE_INTEGER(cr.var_idx), immediate_val));
                }
              }
              else
              {
                cr.type = CR_IMMEDIATE;
                cr.immediate_val = immediate_val;
              }
            }
          }

          goto do_return;
        }
      }
      else if (sym == interp->s_inc)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 1, 2);

        obj o_1 = NTH(o, 1);
        obj o_2 = ASIZE(o) > 2 ? NTH(o, 2) : NONE_VALUE;

        i8 ret_var_idx = find_lexical_variable_idx(cs, o_1);
        if (ret_var_idx < 0)
          COMPILE_ERROR(o_1, &cr, "Variable not found");

        if (ASIZE(o) == 2)
        {
          array_add_obj(interp, code_list, make_array(interp, 3, interp->s_addri, MAKE_INTEGER(ret_var_idx), MAKE_INTEGER(1)));
          cr.type = CR_VARIABLE;
          cr.var_idx = ret_var_idx;
        }
        else
        {
          compile_result cr_arg1 = compile_expression(interp, o_2, cs, code_list, 1, -1, 0, 0);
          PROPAGATE_COMPILE_ERROR(o, &cr_arg1, &cr);
          contains_function_call |= cr_arg1.contains_function_call;

          switch (cr_arg1.type)
          {
            case CR_ERROR:
            default:
              break;
            case CR_IMMEDIATE:
              if(IS_INTEGER(cr_arg1.immediate_val))
              {
                array_add_obj(interp, code_list, make_array(interp, 3, interp->s_addri, MAKE_INTEGER(ret_var_idx), INC(interp, cr_arg1.immediate_val)));
                cr.type = CR_VARIABLE;
                cr.var_idx = ret_var_idx;
              }
              else
              {
                COMPILE_ERROR(o, &cr, "inc requires a numeric 2nd argument");
              }
              break;
            case CR_VARIABLE:
              array_add_obj(interp, code_list, make_array(interp, 3, interp->s_addrr, MAKE_INTEGER(ret_var_idx), MAKE_INTEGER(cr_arg1.var_idx)));
              cr.type = CR_VARIABLE;
              cr.var_idx = ret_var_idx;
              break;
            case CR_CONDITION:
              break;
          }
        }
      }
      else if (sym == interp->s_define_c)
      {
        COMPILE_CHECK_NUM_ARGS(o, &cr, 1, -1);

        obj el1 = NTH(o, 1);

        obj func_sym = NONE_VALUE;
        u0 *ptr = NULL;
        i1 ptr_ok = 0;

        if (IS_OBJ_ARRAY(el1))
        {
          func_sym = NTH(el1, 0);
          obj ptr_obj = ASIZE(el1) > 1 ? NTH(el1, 1) : NONE_VALUE;

          if (IS_STRING(ptr_obj))
          {
            ptr = load_symbol_any(GET_STRING_STORAGE(ptr_obj));
          }
          else if (IS_INTEGER(ptr_obj))
          {
            ptr = (u0 *)GET_INTEGER(ptr_obj);
            ptr_ok = 1;
          }
          else if (IS_NONE(ptr_obj))
          {
            ptr = NULL;
            ptr_ok = 1;
          }
        }
        else if (IS_SYMBOL(el1))
        {
          func_sym = el1;
          ptr = load_symbol_any(get_symbol_string(func_sym));
        }
        else
        {
          COMPILE_ERROR(el1, &cr, "Invalid function specification");
        }

        if (ptr_ok || ptr)
        {
          /* C function */
          // FMT(STDOUT_H, "Found C function for %s\n", get_symbol_string(func_sym));
          obj func = make_function(FT_EXT_PROTOTYPE, ptr, 0, -1, NONE_VALUE);
          function_t *f = (function_t *)GET_POINTER(func);

          f->arg_types = array_copy(interp, o, 2);

          // add_global_function_value(&interp->globals, func_sym, func, 0);
          set_symbol_function_value(func_sym, func);
        }
        else
        {
          COMPILE_ERROR(func_sym, &cr, "Symbol not bound to a function");
        }

        cr.type = CR_IMMEDIATE;
        cr.immediate_val = NONE_VALUE;
      }
      else if (sym == interp->s_debug_break)
      {
        array_add_obj(interp, code_list, make_array(interp, 1, interp->s_debug_break));
        cr.type = CR_IMMEDIATE;
        cr.immediate_val = NONE_VALUE;
      }
      else
      {
        /* general function call */
        i8 idx;
find_function:
        idx = symbol_has_function_value(sym);

        if (idx > 0)
        {
#if 1
          symbol_t *sym_object = GET_SYMBOL(sym);
          obj function_value = sym_object->function_value;
#else
          obj function_value = cs->glob->function_value[idx];
#endif

          if (IS_NONE(function_value))
            COMPILE_ERROR(sym, &cr, "Symbol not bound to a function");

          contains_function_call |= 1;

          /* code for getting arguments */

          function_t *f = (function_t *)GET_POINTER(function_value);

          /* check argument count */

          i8 arg_count = ASIZE(o) - 1;

          if (f->min_arg_count != -1 && arg_count < f->min_arg_count)
            COMPILE_ERROR(sym, &cr, "Not enough arguments, got %lld, expected %lld", arg_count, f->min_arg_count);

          if (f->max_arg_count != -1 && arg_count > f->max_arg_count)
            COMPILE_ERROR(sym, &cr, "Too many arguments, got %lld, expected %lld", arg_count, f->max_arg_count);

          /* compile arguments - if arguments contain a function call (reusing call argument area) use intermediate variable */

#define MAX_ARGUMENTS 100
          i8 argument_variables[MAX_ARGUMENTS];
          u1 argument_is_immediate[MAX_ARGUMENTS];
          obj argument_immediates[MAX_ARGUMENTS];
          memory_set(argument_is_immediate, 0, sizeof(argument_is_immediate));
          memory_set(argument_immediates, 0, sizeof(argument_immediates));

          /* if function is external with defined arguments we don't need to have argument variables on stack */
          i1 argument_variable_required = (f->function_type == FT_EXT_PROTOTYPE) ? 0 : 1;

          vec_t *decref_arg_vars = VEC_ALLOC(u8, 0, 20);
          obj argument_code = make_array(interp, 0);
          for (i8 i = 1; i < ASIZE(o); i++)
          {
            obj arg = NTH(o, i);

            obj arg1_code = make_array(interp, 0); // code for computing this argument

            /*
             * Code is compiled without target variable
             *
             * If result is immediate or a variable (direct lexical variable of function argument)
             * use 1 move at the call site. If it is a larger expression use a temporary variable and then
             * a move. This is because before compiling the expressin we don't know if the expression uses
             * call registers and also call registers can't be mapped to CPU registers so in theory it is possible
             * to produce worse performance. Without 2-pass compiling we can't determine if an argument expression
             * should be stored in an argument variable or a temporary argument.
             */
            compile_result cr_arg1 = compile_expression(interp, arg, cs, arg1_code, 1, -1, 0, 0);
            PROPAGATE_COMPILE_ERROR(o, &cr_arg1, &cr);

            if (cr_arg1.type == CR_IMMEDIATE)
            {
              array_append(interp, code_list, arg1_code, 1); /* can also have arg code */
              if (argument_variable_required)
              {
                i8 arg_var_idx = find_or_allocate_call_argument(cs, i - 1);
                array_add_obj(interp, argument_code, make_array(interp, 3, interp->s_moveri, MAKE_INTEGER(arg_var_idx), INC(interp, cr_arg1.immediate_val)));
                if (IS_ALLOCATED(cr_arg1.immediate_val))
                  VEC_PUSHBACK(u8, decref_arg_vars, arg_var_idx);
                argument_variables[i - 1] = arg_var_idx;
              }
              else
              {
                argument_is_immediate[i - 1] = 1;
                argument_immediates[i - 1] = cr_arg1.immediate_val;
                argument_variables[i - 1] = -1;
              }
            }
            else
            {
              if (cr_arg1.contains_function_call)
              {
                /* we need to use a temporary variable and put code before actual argument initialization */
                i8 var_idx = result_to_variable(interp, cs, arg1_code, &cr_arg1);
                array_append(interp, code_list, arg1_code, 1);
                if (argument_variable_required)
                {
                  i8 arg_var_idx = find_or_allocate_call_argument(cs, i - 1);
                  /* in argument code copy temporary variable to the argument variable */
                  array_add_obj(interp, argument_code, make_array(interp, 3, interp->s_moverr, MAKE_INTEGER(arg_var_idx), MAKE_INTEGER(var_idx)));
                  if (cs->vars[var_idx].kind == VAR_LEXICAL || cs->vars[var_idx].kind == VAR_ARGUMENT)
                  {
                  }
                  else if (cs->vars[var_idx].kind == VAR_TEMPORARY)
                  {
                    VEC_PUSHBACK(u8, decref_arg_vars, arg_var_idx);
                  }
                  else
                  {
                    COMPILE_ERROR(sym, &cr, "Unsupported variable kind in compiling function arguments");
                  }
                  argument_variables[i - 1] = arg_var_idx;
                }
                else
                {
                  if (cs->vars[var_idx].kind == VAR_TEMPORARY)
                  {
                    VEC_PUSHBACK(u8, decref_arg_vars, var_idx); // TODO correct?
                  }
                  argument_variables[i - 1] = var_idx;
                }
              }
              else
              {
                /* we can use the code at the point of argument initialization without a temporary variable */
                array_append(interp, argument_code, arg1_code, 1);
                i8 var_idx = result_to_variable(interp, cs, argument_code, &cr_arg1);
                if (argument_variable_required)
                {
                  /* check var idx type */
                  if (cs->vars[var_idx].kind == VAR_LEXICAL || cs->vars[var_idx].kind == VAR_ARGUMENT)
                  {
                    i8 arg_var_idx = find_or_allocate_call_argument(cs, i - 1);
                    array_add_obj(interp, argument_code, make_array(interp, 3, interp->s_moverr, MAKE_INTEGER(arg_var_idx), MAKE_INTEGER(var_idx)));
                    // VEC_PUSHBACK(u8, decref_arg_vars, arg_var_idx);
                    argument_variables[i - 1] = arg_var_idx;
                  }
                  else if (cs->vars[var_idx].kind == VAR_TEMPORARY)
                  {
#if 0
                    // don't 'rename' the variable kind to call argument (produces many call argument duplicates
                    cs->vars[var_idx].kind = VAR_CALL_ARGUMENT;
                    cs->vars[var_idx].var_sequence_number = i - 1;
                    VEC_PUSHBACK(u8, decref_arg_vars, var_idx);
                    argument_variables[i - 1] = var_idx;
#else
                    /* add a move from temporary variable */
                    i8 arg_var_idx = find_or_allocate_call_argument(cs, i - 1);
                    array_add_obj(interp, argument_code, make_array(interp, 3, interp->s_moverr, MAKE_INTEGER(arg_var_idx), MAKE_INTEGER(var_idx)));
                    VEC_PUSHBACK(u8, decref_arg_vars, arg_var_idx);
                    argument_variables[i - 1] = arg_var_idx;
#endif
                  }
                  else
                  {
                    COMPILE_ERROR(sym, &cr, "Unsupported variable kind in compiling function arguments");
                  }
                }
                else
                {
                  /* don't require a special argument variable, can use existing var_idx */
                  if (cs->vars[var_idx].kind == VAR_TEMPORARY)
                  {
                    VEC_PUSHBACK(u8, decref_arg_vars, var_idx); // TODO correct?
                  }
                  argument_variables[i - 1] = var_idx;
                }
              }
            }

            DEC(interp, arg1_code);
          }

          // FMT(STDOUT_H, "Argument code: "); print_object(STDOUT_H, argument_code); FMT(STDOUT_H, "\n");
          array_append(interp, code_list, argument_code, 1);
          DEC(interp, argument_code);

          if (f->function_type == FT_BYTECODE)
          {
            i8 var_idx = result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs); /* return value */
            array_add_obj(interp, code_list, make_array(interp, 4, interp->s_call, INC(interp, function_value), MAKE_INTEGER(var_idx), MAKE_INTEGER(arg_count)));

            if (keep_result)
            {
              cr.type = CR_VARIABLE;
              cr.var_idx = var_idx;
            }
            else
            {
              array_add_obj(interp, code_list, make_array(interp, 2, interp->s_decref, MAKE_INTEGER(var_idx)));
            }
          }
          else if (f->function_type == FT_BUILTIN)
          {
            i8 var_idx = keep_result ? (result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs)) : -1;
            // if keep_result = 0, a special call internal bytecode is used which doesn't produce a result
            array_add_obj(interp, code_list, make_array(interp, 4, interp->s_call_internal, MAKE_INTEGER(var_idx), INC(interp, function_value), MAKE_INTEGER(arg_count)));
            if (keep_result)
            {
              cr.type = CR_VARIABLE;
              cr.var_idx = var_idx;
            }
          }
          else if (f->function_type == FT_EXT)
          {
            i8 var_idx = keep_result ? (result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs)) : -1;
            // if keep_result = 0, a special call internal bytecode is used which doesn't produce a result
            array_add_obj(interp, code_list, make_array(interp, 4, interp->s_call_external, MAKE_INTEGER(var_idx), INC(interp, function_value), MAKE_INTEGER(arg_count)));

            if (keep_result)
            {
              cr.type = CR_VARIABLE;
              cr.var_idx = var_idx;
            }
          }
          else if (f->function_type == FT_EXT_PROTOTYPE)
          {
            i8 var_idx = keep_result ? (result_var_idx >= 0 ? result_var_idx : allocate_temporary_variable(cs)) : -1;
            obj arg_types = f->arg_types;
            /* prepare arguments - conversion to specified arg types */
            if (ASIZE(arg_types) - 1 != arg_count)
            {
              COMPILE_ERROR(sym, &cr, "Argument count %lld doesn't equal the defined number of arguments %lld",
                  arg_count, ASIZE(arg_types) - 1);
            }

            i8 num_real_args = 0;
            for (i8 i = ASIZE(arg_types) - 1; i >= 1; i--)
            {
              if (NTH(arg_types, i) == interp->s_float || NTH(arg_types, i) == interp->s_double)
                num_real_args++;
            }

            i8 num_int_args = ASIZE(arg_types) - 1 - num_real_args;

#ifdef WIN32_CALLING_CONVENTION
            i8 stack_allocated = MAX_MACRO(num_int_args + num_real_args, NUM_REG_ARGUMENTS); // win32 has shadow space for reg arguments
#else
            i8 stack_allocated = 0;
            if (num_int_args - NUM_INT_REG_ARGUMENTS > 0) stack_allocated += num_int_args - NUM_INT_REG_ARGUMENTS;
            if (num_real_args - NUM_FLOAT_REG_ARGUMENTS > 0) stack_allocated += num_real_args - NUM_FLOAT_REG_ARGUMENTS;
            i8 on_stack_counter = stack_allocated;
#endif


            // align stack to 16 bytes
            i8 stack_allocated_bytes = (stack_allocated & 0x1 ? stack_allocated + 1 : stack_allocated) * 8;

            /* always allocate stack on rsp in multiples of 16 (calling convention) */
            array_add_obj(interp, code_list, make_array(interp, 2, interp->s_call_external2_prepare,
                  MAKE_INTEGER(stack_allocated_bytes)));

            for (i8 i = ASIZE(arg_types) - 1; i >= 1; i--)
            {
              obj arg_type = NTH(arg_types, i);
              i8 arg_idx = i - 1; // argument index 0... (0 is the first argument)
              i8 var_idx = argument_variables[i - 1];
              /* do argument allocation logic */

              if (arg_type == interp->s_double || arg_type == interp->s_float)
              {
#ifdef WIN32_CALLING_CONVENTION
                //i8 dst_reg_num = (arg_idx >= NUM_REG_ARGUMENTS) ? --on_stack_counter : arg_idx;
                i8 dst_reg_num = arg_idx;
#else
                i8 dst_reg_num = (num_real_args > NUM_FLOAT_REG_ARGUMENTS) ? (--on_stack_counter + NUM_FLOAT_REG_ARGUMENTS) : (num_real_args - 1);
#endif
                num_real_args--;
                if (argument_is_immediate[arg_idx])
                  array_add_obj(interp, code_list, make_array(interp, 3, arg_type == interp->s_double ? interp->s_f8argi : interp->s_f4argi,
                        MAKE_INTEGER(dst_reg_num), argument_immediates[arg_idx]));
                else
                  array_add_obj(interp, code_list, make_array(interp, 3, arg_type == interp->s_double ? interp->s_f8arg : interp->s_f4arg,
                        MAKE_INTEGER(dst_reg_num), MAKE_INTEGER(var_idx)));
              }
              else
              {
#ifdef WIN32_CALLING_CONVENTION
                //i8 dst_reg_num = (arg_idx >= NUM_REG_ARGUMENTS) ? --on_stack_counter : arg_idx;
                i8 dst_reg_num = arg_idx;
#else
                i8 dst_reg_num = (num_int_args > NUM_INT_REG_ARGUMENTS) ? (--on_stack_counter + NUM_INT_REG_ARGUMENTS) : (num_int_args - 1);
#endif
                num_int_args--;
                if (arg_type == interp->s_ptr)
                {
                  if (argument_is_immediate[arg_idx])
                    array_add_obj(interp, code_list, make_array(interp, 3, interp->s_ptrargi, MAKE_INTEGER(dst_reg_num), argument_immediates[arg_idx]));
                  else
                    array_add_obj(interp, code_list, make_array(interp, 3, interp->s_ptrarg, MAKE_INTEGER(dst_reg_num), MAKE_INTEGER(var_idx)));
                }
                else
                {
                  /* all integer arguments */
                  if (argument_is_immediate[arg_idx])
                    array_add_obj(interp, code_list, make_array(interp, 3, interp->s_ulongargi, MAKE_INTEGER(dst_reg_num), argument_immediates[arg_idx]));
                  else
                    array_add_obj(interp, code_list, make_array(interp, 3, interp->s_ulongarg, MAKE_INTEGER(dst_reg_num), MAKE_INTEGER(var_idx)));
                }
              }
            }
            array_add_obj(interp, code_list, make_array(interp, 4, interp->s_call_external2, MAKE_INTEGER(var_idx), INC(interp, function_value),
                  MAKE_INTEGER(stack_allocated_bytes)));

            if (keep_result)
            {
              cr.type = CR_VARIABLE;
              cr.var_idx = var_idx;
            }
          }

          for (i8 i = 0; i < VEC_SIZE(u8, decref_arg_vars); i++)
            array_add_obj(interp, code_list, make_array(interp, 2, interp->s_decref, MAKE_INTEGER(VEC_NTH(u8, decref_arg_vars, i))));

          VEC_FREE(decref_arg_vars);

          goto do_return;
        }
        else
        {
          u0 *ptr = load_symbol_any(get_symbol_string(sym));

          if (ptr)
          {
            /* C function */
            // FMT(STDOUT_H, "Found C function for %s\n", get_symbol_string(sym));
            obj func = make_function(FT_EXT, ptr, 0, -1, NONE_VALUE);

            // add_global_function_value(&interp->globals, sym, func, 0);
            set_symbol_function_value(sym, func);
            goto find_function;
          }
          else
          {
            COMPILE_ERROR(sym, &cr, "Symbol not bound to a function");
          }
        }
      }
    }
  }
  else
  {
    COMPILE_ERROR(o, &cr, "Can't compile");
  }

do_return:
  cr.contains_function_call |= contains_function_call;

  if (result_var_idx < 0)
    return cr;

  if (force_variable_result)
  {
    switch (cr.type)
    {
      case CR_ERROR:
        break;
      case CR_IMMEDIATE:
        /* add move to result variable */
        array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moveri, MAKE_INTEGER(result_var_idx), INC(interp, cr.immediate_val)));
        cr.type = CR_VARIABLE;
        cr.var_idx = result_var_idx;
        break;
      case CR_VARIABLE:
        if (cr.var_idx != result_var_idx)
        {
          PRINT_ERROR("Inefficient: variable index mismatch %lld %lld, inserting a move\n", cr.var_idx, result_var_idx);
          PRINT_ERROR("While compiling: ");
          print_object(STDERR_H, o);
          FMT(STDERR_H, "\n");
          array_add_obj(interp, code_list, make_array(interp, 3, interp->s_moverr, MAKE_INTEGER(result_var_idx), MAKE_INTEGER(cr.var_idx)));
          cr.var_idx = result_var_idx;
        }
        break;
      case CR_CONDITION:
        break;
      default:
        PRINT_ERROR("Unknown compile result type! (%lld)\n", cr.type);
        break;
    }
  }

  return cr;
}

typedef i8 (*array_pred_check_func)(obj x);
i8 array_pred_check(obj o, i8 offset, array_pred_check_func f)
{
  for (i8 i = offset; i < ASIZE(o); i++)
  {
    obj tmp = NTH(o, i);
    i8 res = f(tmp);
    if (res != 0)
      return res;
  }

  return 0;
}

i8 is_symbol(obj o)
{
  return IS_SYMBOL(o) ? 0 : -1;
}

u0 init_compile_struct(interpreter_t *interp, compiler_state *cs)
{
  memory_set(cs, 0, sizeof(compiler_state));
  // cs->glob = &interp->globals;
  cs->ir_code = make_array(interp, 0);
  cs->bytecode = VEC_ALLOC(u8, 0, 20);
  cs->immediates = make_array(interp, 0);

  cs->lexical_frames_pos = 1; /* add 0th frame */
}

u0 deinit_compile_struct(interpreter_t *interp, compiler_state *cs)
{
  DEC(interp, cs->ir_code);
  cs->ir_code = NONE_VALUE;

  VEC_FREE(cs->bytecode);

  DEC(interp, cs->immediates);
  cs->immediates = NONE_VALUE;
}

obj compile_function(interpreter_t *interp, obj o, compiler_state *cs_outer, compile_result *cr_out)
{
  if (NTH(o, 0) != interp->s_define)
  {
    PRINT_ERROR("Incorrect function definition\n");
    return NONE_VALUE;
  }

  compiler_state* cs = MALLOC_TYPE(compiler_state);
  init_compile_struct(interp, cs);

  obj second_obj = NTH(o, 1);

  const i8 arg_offset = 1; // args start after the function name
  i8 arg_count = ASIZE(second_obj) - arg_offset;

  if (array_pred_check(second_obj, arg_offset, &is_symbol))
  {
    PRINT_ERROR("Arguments should be symbols\n");
    deinit_compile_struct(interp, cs);
    free(cs);
    return NONE_VALUE;
  }

  /* add arguments as variables before compilation */
  for (i8 i = 0; i < arg_count; i++)
  {
    obj sym = NTH(second_obj, arg_offset + i);

    i8 var_idx = new_variable(cs, VAR_ARGUMENT, i, sym, 0, NONE_VALUE);
    add_lexical_variable(cs, sym, var_idx);
  }

  compile_result cr = compile_list(interp, o, cs, cs->ir_code, 2, 1, -1);
  result_to_variable(interp, cs, cs->ir_code, &cr);
  if (cr_out)
    *cr_out = cr;

  /* code for decrefing lexical variables */
  for (i8 i = cs->lexical_vars_pos - 1; i >= cs->lexical_frames[cs->lexical_frames_pos - 1]; i--)
  {
    i8 var_idx = cs->lexical_vars[i].var_idx;
    if (cs->vars[var_idx].kind == VAR_ARGUMENT) /* we must not decref arguments - they are 'owned' by the calling code */
      continue;
    if (cr.type != CR_VARIABLE || cr.var_idx != var_idx) /* if variable is not used as a return value */
    {
      array_add_obj(interp, cs->ir_code, make_array(interp, 2, interp->s_decref, MAKE_INTEGER(var_idx)));
    }
    else
      PRINT_ERROR("Unexpected - lexical variable is returned as a return value\n");
  }

  if (cr.type != CR_ERROR)
  {
    array_add_obj(interp, cs->ir_code, make_array(interp, 2, interp->s_ret, MAKE_INTEGER(cr.var_idx)));

    FMT(STDOUT_H, "Intermediate representation code:\n");
    print_object(STDOUT_H, cs->ir_code);
    FMT(STDOUT_H, "\n");

    i8 ret_status = compile_to_bytecode(interp, cs->ir_code, cs);

    if (ret_status < 0)
    {
      FMT(STDERR_H, "Compile to bytecode failed.\n");
    }
    else
    {
      print_bytecode(&VEC_NTH(u8, cs->bytecode, 0), VEC_SIZE(u8, cs->bytecode));

      obj f = make_function(FT_BYTECODE, memory_duplicate(&VEC_NTH(u8, cs->bytecode, 0), VEC_SIZE(u8, cs->bytecode) * sizeof(u8)),
          arg_count, arg_count, cs->immediates);
      cs->immediates = NONE_VALUE;
      function_t *f_ptr = (function_t *)GET_POINTER(f);
      f_ptr->code = INC(interp, o);
      f_ptr->ir_code = INC(interp, cs->ir_code);
      f_ptr->bytecode_count = VEC_SIZE(u8, cs->bytecode);
      deinit_compile_struct(interp, cs);
      free(cs);
      return f;
    }
  }

  deinit_compile_struct(interp, cs);
  free(cs);

  return NONE_VALUE;
}

obj execute_bytecode(interpreter_t *interp, vec_t *bytecode)
{
  u8 register_file[10 * 1024];

  u8 *bytecode_ptr = &VEC_NTH(u8, bytecode, 0);
  i8 count = VEC_SIZE(u8, bytecode);

  print_bytecode(bytecode_ptr, count);

  obj ret = (obj)vm_execute(bytecode_ptr, &register_file[ARRAY_SIZE(register_file)], interp);

  return ret;
}

u0 init_parse_state(interpreter_t *interp, parse_state *ps)
{
  ps->begin = NULL;
  ps->end = NULL;
  ps->pos = ps->begin;
  ps->state = STATE_NEXT_TOKEN;
  ps->stack_pos = 0;
  ps->stack[0] = make_array(interp, 0);
  ps->stack_expr_parse_type[0] = EXPR_NORMAL;
}

u0 set_parse_input(parse_state *ps, const i1 *begin, const i1 *end)
{
  ps->begin = begin;
  ps->end = end;
  ps->pos = ps->begin;
}

#define INTERNAL_FUNCTION(fun_name) obj (fun_name)(interpreter_t *_interp, u8 *_stack, u8 _num_args, i8 need_result)
#define INTERPRETER_POINTER (_interp)
#define GET_ARG(i) ((_stack)[i + 1])
#define NUM_ARGS (_num_args)
#define NEED_RESULT (need_result)

INTERNAL_FUNCTION(s_quit)
{
  i8 quit_value = 0;
  if (NUM_ARGS > 0 && IS_INTEGER(GET_ARG(0)))
    quit_value = GET_INTEGER(GET_ARG(0));

  exit(quit_value);

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_get_os)
{
  const i1 *name =
#ifdef _WIN32
    "Windows"
#else
    "Linux"
#endif
    ;
  return make_string(INTERPRETER_POINTER, name, -1, 1);
}

i1 deep_compare_objects(obj o1, obj o2)
{
  if (o1 == o2)
  {
    return 1;
  }

  if (IS_ARRAY(o1) && IS_ARRAY(o2))
  {
    if (GET_ARRAY_ELEMENT_TYPE(o1) == GET_ARRAY_ELEMENT_TYPE(o2) &&
       ASIZE(o1) == ASIZE(o2))
    {
      // compare contents
      if (IS_OBJ_ARRAY(o1))
      {
        for (i8 i = 0; i < ASIZE(o1); i++)
        {
          obj o11 = NTH(o1, i);
          obj o12 = NTH(o2, i);
          if (o11 != o12 && !deep_compare_objects(o11, o12))
            return 0;
        }
      }
      else
      {
        array_t *a1 = GET_ARR(o1);
        if (a1 && memory_compare(GET_ARRAY_STORAGE(u1, o1), GET_ARRAY_STORAGE(u1, o2), a1->size * a1->element_size) == 0)
        {
          return 1;
        }
      }
    }
  }

  return 0;
}

INTERNAL_FUNCTION(s_equal)
{
  obj arg0 = GET_ARG(0);
  obj arg1 = GET_ARG(1);

  if (deep_compare_objects(arg0, arg1))
  {
    return MAKE_INTEGER(1);
  }

  return NONE_VALUE;
}

i8 execute_string(interpreter_t* interp, parse_state* ps, const i1* text, i8 text_len);

i8 read_stdin(i1 *buffer, i8 buffer_size)
{
#ifdef _MSC_VER
  u4 ret = 0;
  if (!ReadConsoleA(GetStdHandle(STD_INPUT_HANDLE),
      buffer,
      buffer_size - 1,
      &ret,
      NULL))
  {
    ret = -1;
  }
#else
  i8 ret = read(STDIN_FILENO, buffer, buffer_size - 1);
#endif
  if (ret < 0)
  {
#ifdef _MSC_VER
    char *s = GetErrorString(GetLastError());
    FMT(STDERR_H, "read() : %s", s);
    LocalFree(s);
#else
    FMT(STDERR_H, "read() : %s", strerror(errno));
#endif
    buffer[0] = '\0';
    return 0;
  }
  if (ret >= 0)
  {
    buffer[ret] = '\0';
  }
  return ret;
}

INTERNAL_FUNCTION(s_process_stdin)
{
  static parse_state ps;
  static i1 not_first_run;

  if (!not_first_run)
  {
    init_parse_state(INTERPRETER_POINTER, &ps);
    not_first_run = 1;
  }

  if (!stream_has_data(STDIN_H))
  {
    return NONE_VALUE;
  }

  do
  {
    i1 buffer[1024];
    buffer[0] = '\0';

    i1 *text = buffer;

    {
      // FMT(STDOUT_H, "> ");
      // FLUSH_STREAM(STDOUT_H);
      if (read_stdin(buffer, sizeof(buffer)) == 0)
        break;
    }

    i8 ret = execute_string(INTERPRETER_POINTER, &ps, text, str_length(text));

#if 0
    /* read more lines */
    while (ret == -2)
    {
      // FMT(STDOUT_H, "... ");
      // FLUSH_STREAM(STDOUT_H);
      if (read_stdin(buffer, sizeof(buffer)) == 0)
        break;
      ret = execute_string(INTERPRETER_POINTER, &ps, text, str_length(text));
    }
#endif

    if (ret == -1)
    {
      FMT(STDERR_H, "Parsing failed.\n");
    }

    if (ret == -3)
    {
    }

  } while (0);

  return NONE_VALUE;
}

u0 regularize_filename(i1 *filename, i1 separator)
{
  i1 *dst = filename;
  i1 *src = filename;

  i1 had_separator = 0;

  while (*src)
  {
    if (*src == '\\' || *src == '/')
    {
      if (!had_separator)
      {
        had_separator = 1;
        *dst++ = separator;
      }
    }
    else
    {
      had_separator = 0;
      *dst = *src;
      dst++;
    }

    src++;
  }

  *dst = '\0';
}

i8 load_file(interpreter_t *interp, const i1* filename)
{
  i1 *text = NULL;

  const i1 *path = ".";
  i8 i_path = 0;

  i1 file_path[1024];
  file_path[0] = '\0';

  do
  {
    i1 temp_filename[1024];

    SNPRINTF(temp_filename, sizeof(temp_filename),
        "%s/%s", path, filename);
    regularize_filename(temp_filename, '/');

    FMT(STDOUT_H, "Trying to read \"%s\"\n", temp_filename);
    text = read_file_string(temp_filename, NULL);

    if (!text)
    {
      SNPRINTF(temp_filename, sizeof(temp_filename),
          "%s/%s.lisp", path, filename);
      regularize_filename(temp_filename, '/');

      FMT(STDOUT_H, "Trying to read \"%s\"\n", temp_filename);
      text = read_file_string(temp_filename, NULL);
    }

    if (text)
    {
      i1 *chr = strrchr(temp_filename, '/');
      if (chr)
        *chr = '\0';
      str_copy(file_path, temp_filename);
    }
    else
    {
      if (i_path < interp->file_search_path_count)
        path = interp->file_sarch_path[i_path++];
      else
        break;
    }
  } while (!text);

  if (!text)
  {
    return -10;
  }

  parse_state ps;
  init_parse_state(interp, &ps);

  str_copy(interp->file_sarch_path[interp->file_search_path_count], file_path);

  interp->file_search_path_count++;

  i8 ret = execute_string(interp, &ps, text, str_length(text));

  interp->file_search_path_count--;
  free(text);

  return ret;
}

INTERNAL_FUNCTION(s_load_file)
{
  const i1 *filename = GET_STRING_STORAGE(GET_ARG(0));

  i8 ret = load_file(INTERPRETER_POINTER, filename);

  if (ret == -10)
  {
    FMT(STDERR_H, "Failed to read file \"%s\"\n", filename);
  }
  else if (ret == -1)
  {
    FMT(STDERR_H, "Parsing failed.\n");
  }
  else if (ret == -3)
  {
    FMT(STDERR_H, "Parsing failed.\n");
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_to_integer)
{
  if (IS_INTEGER(GET_ARG(0)))
    return GET_ARG(0);
  if (IS_REAL(GET_ARG(0)))
    return MAKE_INTEGER((i8)TO_F8(GET_ARG(0)));

  // TODO runtime error
  return MAKE_INTEGER(0);
}

INTERNAL_FUNCTION(s_to_real)
{
  if (IS_REAL(GET_ARG(0)))
    return GET_ARG(0);
  if (IS_INTEGER(GET_ARG(0)))
    return MAKE_REAL(GET_INTEGER(GET_ARG(0)));

  // TODO runtime error
  return MAKE_REAL(0);
}

INTERNAL_FUNCTION(s_sleep)
{
  f8 sleep_time = 0.0;

  if (IS_INTEGER(GET_ARG(0)))
    sleep_time = GET_INTEGER(GET_ARG(0));
  else if (IS_REAL(GET_ARG(0)))
    sleep_time = TO_F8(GET_ARG(0));
  else
    RUNTIME_ERROR("Argument should be numeric\n");

  if (sleep_time > 0.0)
  {
    sleep_s(sleep_time);
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_get_time)
{
  return MAKE_REAL(get_time());
}

INTERNAL_FUNCTION(s_seed_random)
{
  srand(((u8)GET_ARG(0) >> 32) ^ (u8)GET_ARG(0));

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_random)
{
  f8 rand_real = (f8)rand() / (f8)RAND_MAX;

  return MAKE_REAL(rand_real);
}

INTERNAL_FUNCTION(s_random_integer)
{
  if (IS_INTEGER(GET_ARG(0)))
  {
    i8 random_integer = ((i8)rand() << 32) | (u8)rand();
    return MAKE_INTEGER(random_integer % GET_INTEGER(GET_ARG(0)));
  }
  else
  {
    RUNTIME_ERROR("Type of the first argument not integer");
    return NONE_VALUE;
  }
}

INTERNAL_FUNCTION(s_random_gauss)
{
  i8 val = 0;
  do {
    val = rand();
  } while (val == 0);

  f8 rand_real = (f8)val / (f8)RAND_MAX;
  f8 rand_real2 = (f8)rand() / (f8)RAND_MAX;

  return MAKE_REAL(sqrt(-2.0 * log(rand_real)) * cos(2.0 * M_PI * rand_real2));
}

INTERNAL_FUNCTION(s_make_array)
{
  if (IS_INTEGER(GET_ARG(0)))
  {
    if (NUM_ARGS == 1)
    {
      return alloc_array(INTERPRETER_POINTER, GET_INTEGER(GET_ARG(0)), ET_ANY);
    }
    else
    {
      i8 et = ET_I1;
      /* expect string argument */
      if (IS_STRING(GET_ARG(1)))
      {
        const i1 *str = GET_STRING_STORAGE(GET_ARG(1));
        if (str_compare(str, "any") == 0)
        {
          et = ET_ANY;
        }
        else
        {
          i8 off = str[0] == 'u' ? 1 : 0;

          switch (str[1])
          {
            case '1': et = ET_I1 + off; break;
            case '2': et = ET_I2 + off; break;
            case '4': et = ET_I4 + off; break;
            case '8': et = ET_I8 + off; break;
          }

          if (str[0] == 'f')
            et = str[1] == '4' ? ET_F4 : ET_F8;
        }
      }

      obj ret = alloc_array(INTERPRETER_POINTER, GET_INTEGER(GET_ARG(0)), et);

      array_t *arr = GET_ARR(ret);

      if (NUM_ARGS > 2)
      {
        /* fill values */
        for (i8 i = 0; i < (NUM_ARGS - 2); i++)
        {
          if (i >= arr->size)
            break;

          set_array_element(INTERPRETER_POINTER, arr, i, GET_ARG(2 + i), 1);
        }
      }

      return ret;
    }
  }
  else
    return NONE_VALUE;
}

INTERNAL_FUNCTION(s_make_list)
{
  if (NUM_ARGS > 0)
  {
    i8 et = ET_ANY;
    obj ret = alloc_array(INTERPRETER_POINTER, NUM_ARGS, et);

    array_t* arr = GET_ARR(ret);

    {
      /* fill values */
      for (i8 i = 0; i < NUM_ARGS; i++)
      {
        if (i >= arr->size)
          break;

        u1* storage = &((u1*)arr->storage)[i * arr->element_size];

        switch (et)
        {
        case ET_ANY:
          *(obj*)storage = INC(INTERPRETER_POINTER, GET_ARG(i));
          break;
#if 0
        case ET_I1:
          *(i1*)storage = get_as_i8(GET_ARG(2 + i), 0);
          break;
        case ET_U1:
          *(u1*)storage = get_as_i8(GET_ARG(2 + i), 0);
          break;
        case ET_I2:
          *(i2*)storage = get_as_i8(GET_ARG(2 + i), 0);
          break;
        case ET_U2:
          *(u2*)storage = get_as_i8(GET_ARG(2 + i), 0);
          break;
        case ET_I4:
          *(i4*)storage = get_as_i8(GET_ARG(2 + i), 0);
          break;
        case ET_U4:
          *(u4*)storage = get_as_i8(GET_ARG(2 + i), 0);
          break;
        case ET_I8:
          *(i8*)storage = get_as_i8(GET_ARG(2 + i), 0);
          break;
        case ET_U8:
          *(u8*)storage = get_as_i8(GET_ARG(2 + i), 0);
          break;
        case ET_F4:
          *(f4*)storage = get_as_f8(GET_ARG(2 + i), 0.0);
          break;
        case ET_F8:
          *(f8*)storage = get_as_f8(GET_ARG(2 + i), 0.0);
          break;
#endif
        }

      }

      return ret;
    }
  }
  else
    return NONE_VALUE;
}

INTERNAL_FUNCTION(s_push)
{
  obj arg0 = GET_ARG(0);

  if (IS_ARRAY(arg0))
  {
    obj arg1 = GET_ARG(1);
    i8 pos = NUM_ARGS > 2 && IS_INTEGER(GET_ARG(2)) ? GET_INTEGER(GET_ARG(2)) : ASIZE(arg0);
    array_insert_obj(INTERPRETER_POINTER, arg0, INC(INTERPRETER_POINTER, GET_ARG(1)), pos);
    return INC(INTERPRETER_POINTER, arg0);
  }
  else
    return NONE_VALUE;
}

INTERNAL_FUNCTION(s_pop)
{
  obj arg0 = GET_ARG(0);

  if (IS_ARRAY(arg0))
  {
    i8 pos = NUM_ARGS > 1 && IS_INTEGER(GET_ARG(1)) ? GET_INTEGER(GET_ARG(1)) : (ASIZE(arg0) - 1);
    obj ret = array_remove_obj(INTERPRETER_POINTER, arg0, pos);
    return ret;
  }
  else
    return NONE_VALUE;
}

INTERNAL_FUNCTION(s_append)
{
  obj arg0 = GET_ARG(0);
  obj arg1 = GET_ARG(1);
  if (IS_ARRAY(GET_ARG(0)) && IS_ARRAY(GET_ARG(1)))
  {
    array_append(INTERPRETER_POINTER, arg0, arg1, 0);
    return INC(INTERPRETER_POINTER, arg0);
  }
  else
    return NONE_VALUE;
}

INTERNAL_FUNCTION(s_address_of_storage)
{
  if (IS_ARRAY(GET_ARG(0)))
    return MAKE_INTEGER((u8)&(GET_ARR(GET_ARG(0)))->storage);

  // throw error
  return MAKE_INTEGER(0);
}

INTERNAL_FUNCTION(s_string_from_c_pointer)
{
  if (IS_INTEGER(GET_ARG(0)))
  {
    return make_string(INTERPRETER_POINTER, (const i1 *)(u8)GET_INTEGER(GET_ARG(0)), -1, 1);
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_read_file_string)
{
  if (IS_STRING(GET_ARG(0)))
  {
    i1 *buf = read_file_string(GET_STRING_STORAGE(GET_ARG(0)), NULL);
    if (buf == NULL)
      return NONE_VALUE;

    return make_string(INTERPRETER_POINTER, buf, -1, 0);
  }

  return NONE_VALUE;
}

u0 trace(function_t *f_ptr)
{
  if (f_ptr->function_type == FT_BYTECODE)
  {
    obj sym = NTH(NTH(f_ptr->code, 1), 0);
    FMT(STDOUT_H, "TRACE %s - bytecode at 0x%llx\n", get_symbol_string(sym), (u8)f_ptr->ptr);
    // FMT(STDOUT_H, "Function code: ");
    // print_object(STDOUT_H, f_ptr->code);
    // FMT(STDOUT_H, "\n");
    // FMT(STDOUT_H, "Function IR code: ");
    // print_object(STDOUT_H, f_ptr->ir_code);
    // FMT(STDOUT_H, "\n");
  }
  else
  {
    FMT(STDOUT_H, "TRACE Function type = %d\n", f_ptr->function_type);
  }
  FLUSH_STREAM(STDOUT_H);
}

u0 trace_function(function_t *f_ptr)
{
  //function_t *f_ptr = (function_t *)GET_POINTER(f);
  //FMT(STDOUT_H, "Show function: \"%s\"\n", function_name);
  FMT(STDOUT_H, "\nTRACE FUNCTION\n", f_ptr->function_type);
  FMT(STDOUT_H, "Function type = %d\n", f_ptr->function_type);
  if (f_ptr->function_type == FT_BYTECODE)
  {
    FMT(STDOUT_H, "Function code: ");
    print_object(STDOUT_H, f_ptr->code);
    FMT(STDOUT_H, "\n");
    FMT(STDOUT_H, "Function IR code: ");
    print_object(STDOUT_H, f_ptr->ir_code);
    FMT(STDOUT_H, "\n");
    FMT(STDOUT_H, "Function bytecode (0x%016llx):\n", (u8)f_ptr->ptr);
    print_bytecode(f_ptr->ptr, f_ptr->bytecode_count);
    FMT(STDOUT_H, "\n");
  }
}

INTERNAL_FUNCTION(s_show_function)
{
  if (IS_STRING(GET_ARG(0)))
  {
    const i1 *function_name = GET_STRING_STORAGE(GET_ARG(0));
    obj sym = make_symbol(INTERPRETER_POINTER, function_name);

    obj f = GET_SYMBOL(sym)->function_value;

    if (IS_NONE(f))
    {
      FMT(STDOUT_H, "Function not bound to symbol %s\n", function_name);
    }
    else if (!IS_FUNCTION(f))
    {
      FMT(STDOUT_H, "Symbol %s function value is not a function (shouldn't happen)\n", function_name);
    }
    else
    {
      function_t *f_ptr = (function_t *)GET_POINTER(f);
      FMT(STDOUT_H, "Show function: \"%s\"\n", function_name);
      FMT(STDOUT_H, "Function type = %d\n", f_ptr->function_type);
      if (f_ptr->function_type == FT_BYTECODE)
      {
        FMT(STDOUT_H, "Function code: ");
        print_object(STDOUT_H, f_ptr->code);
        FMT(STDOUT_H, "\n");
        FMT(STDOUT_H, "Function IR code: ");
        print_object(STDOUT_H, f_ptr->ir_code);
        FMT(STDOUT_H, "\n");
        FMT(STDOUT_H, "Function bytecode:\n");
        print_bytecode(f_ptr->ptr, f_ptr->bytecode_count);
        FMT(STDOUT_H, "\n");
      }
    }
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_print_array)
{
  if (IS_ARRAY(GET_ARG(0)))
  {
    obj a = GET_ARG(0);

    array_t *arr = GET_ARR(a);

    i8 size = arr->size;
    if (NUM_ARGS > 1)
      size = GET_INTEGER(GET_ARG(1)) < arr->size ?  GET_INTEGER(GET_ARG(1)) : arr->size;

    i8 count = 0;
    FMT(STDOUT_H, "Array data:\n");
    for (i8 i = 0; i < size * arr->element_size; i++)
    {
      FMT(STDOUT_H, "%02x ", ((u1 *)arr->storage)[i]);

      if (++count == 16)
      {
        FMT(STDOUT_H, "\n");
        count = 0;
      }
    }
    FMT(STDOUT_H, "\n");

    for (i8 i = 0; i < size; i++)
    {
      const u1 *storage = &((const u1 *)arr->storage)[i * arr->element_size];

      if (arr->element_type == ET_I1)
        FMT(STDOUT_H, "%d ", *(const i1 *)storage);
      else if (arr->element_type == ET_U1)
        FMT(STDOUT_H, "%u ", *(const u1 *)storage);
      else if (arr->element_type == ET_I2)
        FMT(STDOUT_H, "%d ", *(const i2 *)storage);
      else if (arr->element_type == ET_U2)
        FMT(STDOUT_H, "%u ", *(const u2 *)storage);
      else if (arr->element_type == ET_I4)
        FMT(STDOUT_H, "%d ", *(const i4 *)storage);
      else if (arr->element_type == ET_U4)
        FMT(STDOUT_H, "%u ", *(const u4 *)storage);
      else if (arr->element_type == ET_I8)
        FMT(STDOUT_H, "%lld ", *(const i8 *)storage);
      else if (arr->element_type == ET_U8)
        FMT(STDOUT_H, "%llu ", *(const u8 *)storage);
      else if (arr->element_type == ET_F4)
        FMT(STDOUT_H, "%f ", *(const f4 *)storage);
      else if (arr->element_type == ET_F8)
        FMT(STDOUT_H, "%f ", *(const f8 *)storage);
    }

    FMT(STDOUT_H, "\n");
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_load_dynamic_library)
{
  if (IS_STRING(GET_ARG(0)))
  {
    i1 *str0 = GET_STRING_STORAGE(GET_ARG(0));

    u0 *ptr = load_library(str0);
    if (!ptr)
    {
      i1 library_name[1024];

#ifdef _WIN32
      SNPRINTF(library_name, sizeof(library_name), "%s.dll", str0);
#elif defined(__APPLE__) && defined(__MACH__)
      SNPRINTF(library_name, sizeof(library_name), "%s.dylib", str0);
#else
      SNPRINTF(library_name, sizeof(library_name), "%s.so", str0);
#endif

      ptr = load_library(library_name);
    }

    i1 *err = load_library_error();
    if (!ptr)
    {
      PRINT_ERROR("%s", err);
      load_library_free_error(err);
      return MAKE_INTEGER(0);
    }

    return MAKE_INTEGER((u8)ptr);
  }

  return MAKE_INTEGER(0);
}

INTERNAL_FUNCTION(s_get_function_pointer)
{
  i1* str = NULL;

  if (NUM_ARGS == 2 && IS_INTEGER(GET_ARG(0)) && IS_STRING(GET_ARG(1)))
    str = GET_STRING_STORAGE(GET_ARG(1));

  if (NUM_ARGS == 1 && IS_STRING(GET_ARG(0)))
    str = GET_STRING_STORAGE(GET_ARG(0));

  if (str)
  {
    u0 *ptr = NUM_ARGS == 2 ?
      load_symbol((u0 *)GET_INTEGER(GET_ARG(0)), str) : load_symbol_any(str);
    i1 *err = load_library_error();
    if (!ptr)
    {
      PRINT_ERROR("%s\n", err);
      load_library_free_error(err);
      return MAKE_INTEGER(0);
    }

    return MAKE_INTEGER((u8)ptr);
  }

  return MAKE_INTEGER(0);
}

INTERNAL_FUNCTION(s_set_function_pointer)
{
  if (IS_SYMBOL(GET_ARG(0)) && IS_INTEGER(GET_ARG(1)))
  {
    symbol_t *symbol = GET_SYMBOL(GET_ARG(0));

    if (!IS_NONE(symbol->function_value))
    {
      function_t *f = GET_FUNCTION(symbol->function_value);
      f->ptr = (u0 *)GET_INTEGER(GET_ARG(1));
    }
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_print)
{
  for (i8 i = 0; i < NUM_ARGS; i++)
  {
    print_object_no_quotes(STDOUT_H, GET_ARG(i));
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_print_binary)
{
  for (i8 i = 0; i < NUM_ARGS; i++)
  {
    if (i != 0)
      FMT(STDOUT_H, " ");
    FMT(STDOUT_H, "0x%016llx", (u8)GET_ARG(i));
  }
  FMT(STDOUT_H, "\n");

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_and)
{
  for (i8 i = 0; i < NUM_ARGS; i++)
  {
    if (IS_NONE(GET_ARG(i)))
    {
      return NONE_VALUE;
    }
  }

  return MAKE_INTEGER(1);
}

INTERNAL_FUNCTION(s_or)
{
  for (i8 i = 0; i < NUM_ARGS; i++)
  {
    if (!IS_NONE(GET_ARG(i)))
    {
      return MAKE_INTEGER(1);
    }
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_len)
{
  obj o = GET_ARG(0);
  if (IS_ARRAY(o))
  {
    array_t *arr = GET_ARR(o);

    return MAKE_INTEGER(arr->size);
  }

  return MAKE_INTEGER(0);
}

#define MATH_FUNC_1ARG(name, func) \
INTERNAL_FUNCTION(name) \
{ \
  if (IS_REAL(GET_ARG(0))) \
    return MAKE_REAL(func(TO_F8(GET_ARG(0)))); \
  if (IS_INTEGER(GET_ARG(0))) \
    return MAKE_REAL(func((f8)GET_INTEGER(GET_ARG(0)))); \
  return NONE_VALUE; \
}

MATH_FUNC_1ARG(s_sin, sin)
MATH_FUNC_1ARG(s_cos, cos)
MATH_FUNC_1ARG(s_tan, tan)
MATH_FUNC_1ARG(s_sqrt, sqrt)

INTERNAL_FUNCTION(s_abs)
{
  if (IS_REAL(GET_ARG(0)))
  {
    f8 val = TO_F8(GET_ARG(0));
    return MAKE_REAL(val < 0.0 ? -val : val);
  }
  else if (IS_INTEGER(GET_ARG(0)))
  {
    i8 val = GET_INTEGER(GET_ARG(0));
    return MAKE_INTEGER(val < 0 ? -val : val);
  }
  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_int_div)
{
  i8 a1 = get_as_i8(GET_ARG(0), 1);
  i8 a2 = get_as_i8(GET_ARG(1), 1);
  if (a2 != 0)
    return MAKE_INTEGER(a1 / a2);
  else
    return MAKE_INTEGER(1); // TODO error
}

/**
 * Files
 */
#include <stdio.h>
INTERNAL_FUNCTION(s_file_open)
{
  if (IS_STRING(GET_ARG(0)))
  {
    const i1 *open_mode = GET_STRING_STORAGE(GET_ARG(1));
    const i1* mode = open_mode[0] == 'w' ? "wb" : (open_mode[0] == 'a' ? "ab" : "rb");
    FILE *f = fopen(GET_STRING_STORAGE(GET_ARG(0)), mode);

    if (f)
    {
      return MAKE_INTEGER((u8)f);
    }
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_file_close)
{
  if (IS_INTEGER(GET_ARG(0)))
  {
    FILE *f = (FILE *)GET_INTEGER(GET_ARG(0));

    if (f)
      fclose(f);
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_file_size)
{
  if (IS_INTEGER(GET_ARG(0)))
  {
    FILE *f = (FILE *)GET_INTEGER(GET_ARG(0));
    if (f)
    {
      long pos = ftell(f);
      fseek(f, 0, SEEK_END);
      long size = ftell(f);
      fseek(f, pos, SEEK_SET);

      return MAKE_INTEGER(size);
    }
  }
  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_file_seek)
{
  if (IS_INTEGER(GET_ARG(0)))
  {
    FILE *f = (FILE *)GET_INTEGER(GET_ARG(0));
    if (f)
    {
      fseek(f, (long)GET_INTEGER(GET_ARG(1)), SEEK_SET);

      return MAKE_INTEGER(ftell(f));
    }
  }
  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_file_tell)
{
  if (IS_INTEGER(GET_ARG(0)))
  {
    FILE *f = (FILE *)GET_INTEGER(GET_ARG(0));
    if (f)
    {
      return MAKE_INTEGER(ftell(f));
    }
  }
  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_file_read)
{
  if (IS_INTEGER(GET_ARG(0)) && IS_INTEGER(GET_ARG(1)))
  {
    FILE *f = (FILE *)GET_INTEGER(GET_ARG(0));
    i8 count = GET_INTEGER(GET_ARG(1));

    if (f)
    {
      obj o_ret = alloc_array(INTERPRETER_POINTER, count, ET_U1);
      size_t num_bytes = fread(GET_ARRAY_STORAGE(u1, o_ret), 1, count, f);
      if (num_bytes != count)
      {
        array_t *arr = GET_ARR(o_ret);
        arr->size = (u8)num_bytes;
      }
      return o_ret;
    }
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_read_whole_file)
{
  if (IS_STRING(GET_ARG(0)))
  {
    FILE *f = fopen(GET_STRING_STORAGE(GET_ARG(0)), "rb");

    if (f)
    {
      fseek(f, 0, SEEK_END);
      i8 count = ftell(f);

      fseek(f, 0, SEEK_SET);

      //FMT(STDOUT_H, "Count %ld\n", count);

      obj o_ret = alloc_array(INTERPRETER_POINTER, count, ET_U1);
      size_t num_bytes = fread(GET_ARRAY_STORAGE(u1, o_ret), 1, count, f);
      //FMT(STDOUT_H, "num bytes %ld\n", count);
      if (num_bytes != count)
      {
        if (num_bytes < count)
        {
          array_t* arr = GET_ARR(o_ret);
          arr->size = (u8)num_bytes;
        }
        else
        {
          DEC(INTERPRETER_POINTER, o_ret);
          return NONE_VALUE;
        }
      }
      fclose(f);

      return o_ret;
    }
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_file_write)
{
  if (IS_INTEGER(GET_ARG(0)))
  {
    FILE *f = (FILE *)GET_INTEGER(GET_ARG(0));
    obj o_arr = GET_ARG(1);
    i8 count = NUM_ARGS > 2 ? GET_INTEGER(GET_ARG(2)) : ASIZE(o_arr);
    array_t *arr = GET_ARR(o_arr);
    if (IS_STRING(o_arr))
      count = STRSIZE(o_arr);
    else
      count *= arr->element_size;

    if (f)
    {
      size_t num_bytes = fwrite(GET_ARRAY_STORAGE(u1, o_arr), 1, count, f);
      return MAKE_INTEGER(num_bytes);
    }
  }

  return NONE_VALUE;
}

INTERNAL_FUNCTION(s_substring)
{
  if (IS_STRING(GET_ARG(0)) && IS_INTEGER(GET_ARG(1)) && (NUM_ARGS < 3 || IS_INTEGER(GET_ARG(2))))
  {
    const i1* data = GET_STRING_STORAGE(GET_ARG(0));
    i8 start_idx = GET_INTEGER(GET_ARG(1));
    if (start_idx < 0)
      start_idx = 0;
    i8 end_idx = (NUM_ARGS > 2) ? GET_INTEGER(GET_ARG(2)) : STRSIZE(GET_ARG(0));
    if (end_idx < start_idx)
      return NONE_VALUE;

    i8 count = end_idx - start_idx;

    return make_string(INTERPRETER_POINTER, &data[start_idx], count, 1);
  }

  return NONE_VALUE;
}

i8 execute_string(interpreter_t *interp, parse_state *ps, const i1 *text, i8 text_len)
{
  set_parse_input(ps, text, text + text_len);

  parse(interp, ps);

  if (ps->state == STATE_ERROR)
  {
    FMT(STDERR_H, "Parsing failed: %s\n", ps->error_txt);
    if (ps->error_txt)
      free(ps->error_txt);
    return -1;
  }

  /* read more lines */
  if (ps->state != STATE_NEXT_TOKEN || ps->stack_pos != 0)
  {
    return -2; /* incomplete input */
  }

  obj o = ps->stack[0];

  // print_object(STDOUT_H, o); FMT(STDOUT_H, "\n");

  for (i8 i = 0; i < ASIZE(o); i++)
  {
    obj o_i = make_array(interp, 1, INC(interp, NTH(o, i)));

    compiler_state* cs = MALLOC_TYPE(compiler_state);

    double t1, t2;
    if (interp->print_times) t1 = get_time();
    init_compile_struct(interp, cs);

    compile_result cr = compile_list(interp, o_i, cs, cs->ir_code, 0, 1, -1);
    result_to_variable(interp, cs, cs->ir_code, &cr);

    if (interp->print_times) t2 = get_time();
    if (interp->print_times) FMT(STDOUT_H, "Compilation took %f s\n", t2 - t1);

    DEC(interp, o_i);

    if (cr.type == CR_ERROR)
    {
      FMT(STDERR_H, "\x1b[31;1m%s\x1b[0m", cr.str);
      deinit_compile_struct(interp, cs);
      free(cs);
      return -3; /* compile error */
    }
    else
    {
      array_add_obj(interp, cs->ir_code, make_array(interp, 2, interp->s_retc, MAKE_INTEGER(cr.var_idx)));

      FMT(STDOUT_H, "Intermediate representation code:\n");
      print_object(STDOUT_H, cs->ir_code);
      FMT(STDOUT_H, "\n");

      i8 ret_status = compile_to_bytecode(interp, cs->ir_code, cs);
      DEC(interp, cs->ir_code);
      cs->ir_code = NONE_VALUE;

      if (ret_status < 0)
      {
        FMT(STDERR_H, "Compile to bytecode failed.\n");
        break;
      }
      else
      {
        double t1, t2;
        if (interp->print_times) t1 = get_time();
        obj ret = execute_bytecode(interp, cs->bytecode);
        if (interp->print_times) t2 = get_time();
        if (interp->print_times) FMT(STDOUT_H, "Execution took %f s\n", t2 - t1);

        print_object(STDOUT_H, ret); FMT(STDOUT_H, "\n");
        DEC(interp, ret);
      }
    }

    deinit_compile_struct(interp, cs);
    free(cs);
  }

  DEC(interp, o);
  ps->stack[0] = NONE_VALUE;

  return 0;
}

i8 repl(interpreter_t *interp, const i1 *filename)
{
  i8 return_value = 0;

  while (1)
  {
    i1 buffer[1024];
    buffer[0] = '\0';

    i1 *text = buffer;

    if (filename)
    {
      text = read_file_string(filename, NULL);
      if (!text)
      {
        FMT(STDOUT_H, "failed to read file \"%s\"\n", filename);
        return_value = 1;
        break;
      }
    }
    else
    {
      FMT(STDOUT_H, "> ");
      FLUSH_STREAM(STDOUT_H);
      if (read_stdin(buffer, sizeof(buffer)) == 0)
        break;
    }

    parse_state ps;
    init_parse_state(interp, &ps);

    i8 ret = execute_string(interp, &ps, text, str_length(text));

    if (!filename)
    {
      /* read more lines */
      while (ret == -2)
      {
        FMT(STDOUT_H, "... ");
        FLUSH_STREAM(STDOUT_H);
        if (read_stdin(buffer, sizeof(buffer)) == 0)
          break;
        ret = execute_string(interp, &ps, text, str_length(text));
      }
    }

    if (ret == -1)
    {
      FMT(STDERR_H, "Parsing failed.\n");
      goto end_of_loop;
    }

    if (ret == -3)
    {
      if (filename)
      {
        return_value = 1;
        goto end_of_loop;
      }
    }

end_of_loop:
    if (filename)
    {
      free(text);
      filename = NULL;
    }
  }

  return return_value;
}

u0 add_c_function(interpreter_t *interp, const i1 *symbol_name, u0 *ptr, i8 min_arg_count, i8 max_arg_count)
{
  obj sym = make_symbol(interp, symbol_name);
  obj func = make_function(FT_BUILTIN, ptr, min_arg_count, max_arg_count, NONE_VALUE);

  // add_global_function_value(&interp->globals, sym, func, 0);
  set_symbol_function_value(sym, func);
}

u0 init_interpreter(interpreter_t *interp)
{
  static const struct {
    const i1 *str;
    u0 *ptr;
    i8 min_arg_count;
    i8 max_arg_count;
  } function_initializations[] = {
    { "quit", &s_quit, 0, 1 },
    { "get-os", &s_get_os, 0, 0 },
    { "equal", &s_equal, 2, 2 },
    { "process-stdin", &s_process_stdin, 0, 0 },
    { "load-file", &s_load_file, 1, 1 },
    { "to-integer", &s_to_integer, 1, 1 },
    { "to-real", &s_to_real, 1, 1 },
    { "sleep", &s_sleep, 1, 1 },
    { "get-time", &s_get_time, 0, 0 },
    { "seed-random", &s_seed_random, 1, 1 },
    { "random", &s_random, 0, 0 },
    { "random-integer", &s_random_integer, 1, 1 },
    { "random-gauss", &s_random_gauss, 0, 0 },
    { "make-array", &s_make_array, 1, -1 },
    { "make-list", &s_make_list, 0, -1 },
    { "push", &s_push, 2, 3 },
    { "pop", &s_pop, 1, 2 },
    { "append", &s_append, 2, 2 },
    { "address-of-storage", &s_address_of_storage, 1, 1 },
    { "string-from-c-pointer", &s_string_from_c_pointer, 1, 1 },
    { "read-file-string", &s_read_file_string, 1, 1 },
    { "show-function", &s_show_function, 1, 2 },
    { "print-array", &s_print_array, 1, 2 },
    { "load-dynamic-library", &s_load_dynamic_library, 1, 1 },
    { "get-function-pointer", &s_get_function_pointer, 1, 2 },
    { "set-function-pointer", &s_set_function_pointer, 2, 2 },
    { "print", &s_print, 1, -1 },
    { "print-binary", &s_print_binary, 1, -1 },
    { "and", &s_and, 0, -1 }, // TODO make it shortcircuit (compile)
    { "or", &s_or, 0, -1 }, // TODO make it shortcircuit (compile)
    { "len", &s_len, 1, 1 },
    { "sin", &s_sin, 1, 1 },
    { "cos", &s_cos, 1, 1 },
    { "tan", &s_tan, 1, 1 },
    { "sqrt", &s_sqrt, 1, 1 },
    { "abs", &s_abs, 1, 1 },
    { "int/", &s_int_div, 2, 2 },
    { "file-open", &s_file_open, 2, 2 },
    { "file-close", &s_file_close, 1, 1 },
    { "file-size", &s_file_size, 1, 1 },
    { "file-seek", &s_file_seek, 2, 2 },
    { "file-tell", &s_file_tell, 1, 1 },
    { "file-read", &s_file_read, 2, 2 },
    { "read-whole-file", &s_read_whole_file, 1, 1 },
    { "file-write", &s_file_write, 2, 3 },
    { "substring", &s_substring, 2, 3 },
  };

  memory_set(interp, 0, sizeof(interpreter_t));

  interp->print_times = 1;

  /* symbols initialization */
  for (i8 i = 0; i < ARRAY_SIZE(initializations); i++)
    SYMBOL_OBJ(interp, initializations[i].sym_offset) = make_symbol(interp, initializations[i].str);

  for (i8 i = 0; i < ARRAY_SIZE(function_initializations); i++)
    add_c_function(interp, function_initializations[i].str, function_initializations[i].ptr,
        function_initializations[i].min_arg_count, function_initializations[i].max_arg_count);
}

u0 init_addresses(u0)
{
  /* update addresses - done only once */
  for (i8 i = 0; i < instruction_count; i++)
  {
    instruction_address[i] = instruction_offset[i] + (i8)&vm_execute;
#if 0
    FMT(STDOUT_H, "addr %lld  0x%llx + 0x%llx = 0x%llx\n", i,
        instruction_offset[i], (i8)&vm_execute, instruction_address[i]);
#endif
  }
}

i4 main(i4 argc, i1 *argv[])
{
  FMT(STDOUT_H, "lisp\n");
  init_addresses();

  init_interpreter(&global_instance);

#if 0
  interpreter_t* interp = &global_instance;
  obj arg_obj = make_array(interp, 0);
  for (i8 i = 0; i < argc; i++)
  {
    array_add_obj(interp, arg_obj, make_string(interp, argv[i], -1, 1));
  }
#endif

  const i1 *filename = argc > 1 ? argv[1] : NULL;
  if (filename)
  {
    load_file(&global_instance, filename);
  }
  return repl(&global_instance, NULL);
}

