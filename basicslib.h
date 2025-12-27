/**
 * basicslib.h
 *
 * Basic reusable C functionality
 *
 * Created: 2026-05-16
 * Author: Ziga Lenarcic
 *
 * The contents of this file are public domain (not copyrighted).
 */
#ifndef _BASICSLIB_H_
#define _BASICSLIB_H_
#include <stdbool.h>
#include <stdarg.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/stat.h>
#ifdef _MSC_VER
#include <Windows.h>
#else
#include <unistd.h>
#endif

#if (!defined(MALLOC) || !defined(FREE))
#define MALLOC malloc
#define FREE free
#endif

#define MALLOC_TYPE(type) ((type *)malloc(sizeof(type)))
#define MALLOC_ARRAY(type, count) ((type *)malloc(sizeof(type) * count))

/**
 * Macros
 */

#define MIN_MACRO(x, y) ((x) < (y) ? (x) : (y))
#define MAX_MACRO(x, y) ((y) < (x) ? (x) : (y))
#define ARRAY_SIZE(x) (sizeof((x)) / sizeof((x)[0]))
#ifdef _MSC_VER
#define BP() DebugBreak()
#define ATOMIC_ADD_AND_FETCH64(ptr, num) InterlockedAdd64(ptr, num)
#define FORCE_INLINE static inline __forceinline
#else
#define BP() asm("int3; nop")
#define ATOMIC_ADD_AND_FETCH64(ptr, num) __sync_add_and_fetch(ptr, num)
#define FORCE_INLINE static inline __attribute__((always_inline))
#endif

double get_time()
{
#ifdef _MSC_VER
  // unix time (time_t) is (MS FILETIME - 116444736000000000) / 10000000
  FILETIME FileTime;
  GetSystemTimeAsFileTime(&FileTime);
  int64_t t = (int64_t)FileTime.dwHighDateTime << 32 | FileTime.dwLowDateTime;
  return (double)(t - 116444736000000000LL) / 10000000.0;
#else
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return ((double)tv.tv_sec + 0.000001 * tv.tv_usec);
#endif
}

void sleep_s(double sleep_time)
{
#ifdef _MSC_VER
  Sleep((DWORD)(sleep_time * 1000));
#else
  struct timeval tv;

  tv.tv_sec = (long long)sleep_time;
  tv.tv_usec = (long long)(1000000.0 * (sleep_time - (double)tv.tv_sec));

  select(0, NULL, NULL, NULL, &tv);
#endif
}

/**
 * Memory operations
 */

#ifdef _MSC_VER
#include <stdio.h>
typedef long long ssize_t;
#define ALLOW_UNUSED
#define STATIC_FUNCTION ALLOW_UNUSED static
#else
#define ALLOW_UNUSED __attribute__((unused))
#define STATIC_FUNCTION ALLOW_UNUSED static
#endif

#ifdef _MSC_VER
#include <Windows.h>
char *GetErrorString(DWORD error_code)
{
  char *ptr;
  FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER,
      NULL,
      error_code,
      0x0409, // English(US) //0,
      (LPSTR)&ptr,
      0,
      NULL);
  return ptr;
}
#endif

#ifdef _MSC_VER
#include <Psapi.h>
#else
#include <dlfcn.h>
#endif

void *load_symbol(void *library, const char *name)
{
#ifdef _MSC_VER
  return GetProcAddress(library, name);
#else
  dlerror();
  return dlsym(library, name);
#endif
}

void *load_symbol_any(const char *name)
{
#ifdef _MSC_VER
  // try all open modules
  HMODULE hMods[1024];
  DWORD cbNeeded = 0;
  if (EnumProcessModules(GetCurrentProcess(), hMods, sizeof(hMods), &cbNeeded))
  {
    for (int i = 0; i < (cbNeeded/sizeof(HMODULE)); i++)
    {
      void *ptr = load_symbol(hMods[i], name);
      if (ptr)
      {
        return ptr;
      }
    }
  }

  return NULL;
#else
  dlerror();
  return dlsym(RTLD_DEFAULT, name);
#endif
}

void *load_library(const char *name)
{
#ifdef _MSC_VER
  return LoadLibraryA(name);
#else
  dlerror();
  return dlopen(name, RTLD_NOW | RTLD_GLOBAL);
#endif
}

char *load_library_error()
{
#ifdef _MSC_VER
  DWORD error = GetLastError();
  if (error)
  {
    return GetErrorString(error);
  }
  else
  {
    return NULL;
  }
#else
  return dlerror();
#endif
}

void load_library_free_error(char *error)
{
#ifdef _MSC_VER
  if (error)
    LocalFree(error);
#else
#endif
}

STATIC_FUNCTION char memory_compare(const void *input1, const void *input2, long long int length)
{
  const char *i1 = (const char *)input1;
  const char *i2 = (const char *)input2;

  while (length--)
  {
    char diff = *i1 - *i2;
    if (diff)
      return diff;
    i1++;
    i2++;
  }

  return 0;
}

STATIC_FUNCTION void memory_copy(void *dst, const void *src, long long int length)
{
  char *dst1 = (char *)dst;
  const char *src1 = (const char *)src;

  if ((intptr_t)(dst1) > (intptr_t)(src1) && (intptr_t)(dst1) < (intptr_t)(src1) + length)
  {
    // copy beginning with the last byte
    dst1 += length - 1;
    src1 += length - 1;
    while (length--)
    {
      *dst1 = *src1;
      dst1--;
      src1--;
    }
  }
  else if ((intptr_t)(dst1) != (intptr_t)(src1))
  {
    // copy from the first byte
    while (length--)
    {
      *dst1 = *src1;
      dst1++;
      src1++;
    }
  }
}

STATIC_FUNCTION void memory_set(void *dst, unsigned char value, long long int length)
{
  unsigned char *i1 = (unsigned char *)dst;

  while (length--)
  {
    *i1 = value;
    i1++;
  }
}


STATIC_FUNCTION void *memory_duplicate(const void *input, long long int length)
{
  void *ret = (void *)MALLOC(length);
  memory_copy(ret, input, length);
  return ret;
}

STATIC_FUNCTION long long int str_length(const char *input)
{
  long long int ret = 0;
  if (input)
  {
    while (*input)
    {
      ret++;
      input++;
    }
  }
  return ret;
}

STATIC_FUNCTION char str_compare(const void *input1, const void *input2)
{
  const char *i1 = (const char *)input1;
  const char *i2 = (const char *)input2;

  if (!i1 || !i2)
    return 1;

  while (*i1 && *i2)
  {
    char diff = *i1 - *i2;
    if (diff)
      return diff;
    i1++;
    i2++;
  }

  return *i1 - *i2;
}

STATIC_FUNCTION void str_copy(void *dst, const void *src)
{
  char *i1 = (char *)dst;
  const char *i2 = (const char *)src;

  if (!i1 || !i2)
    return;

  while (*i2)
  {
    *i1 = *i2;

    i1++;
    i2++;
  }

  *i1 = *i2;
}

STATIC_FUNCTION char *str_duplicate(const void *input)
{
  return input ? (char *)memory_duplicate(input, str_length(input) + 1) : NULL;
}

/**
 * I/O library
 */

#ifdef _MSC_VER
typedef FILE * io_stream_t;
#define STDOUT_H stdout
#define STDERR_H stderr
#define STDIN_H stdin
#else
/* linux */
typedef int io_stream_t;
#define STDOUT_H STDOUT_FILENO
#define STDERR_H STDERR_FILENO
#define STDIN_H STDIN_FILENO
#endif

#define NUM_TO_HEX(num, base_hex) (((unsigned char)(num) < 10) ? ('0' + (unsigned char)(num)) : ((base_hex) + (unsigned char)(num) - 10))

STATIC_FUNCTION int print_number(char buffer[32], unsigned long long number, int format, int add_hex_prefix)
{
  char num[32];
  int num_i = 0;
  int add_minus = 0;

  switch (format)
  {
    case 0:
      if (number & 0x8000000000000000ULL)
      {
        add_minus = 1;
        number = (unsigned long long)(-(long long)number);
      }
      /* fallthrough */
    case 1:
      do
      {
        num[num_i++] = '0' + (number % 10);
        number /= 10;
      } while (number);
      break;
    case 2:
    case 3:
      do
      {
        num[num_i++] = NUM_TO_HEX(number & 0xf, format == 2 ? 'a' : 'A');
        number >>= 4;
      } while (number);
      break;
  }

  int i = 0;

  if (add_minus)
    buffer[i++] = '-';

  if (add_hex_prefix)
  {
    buffer[i++] = '0';
    buffer[i++] = 'x';
  }

  for (int i_src = 0; i_src < num_i; i_src++)
  {
    buffer[i++] = num[num_i - 1 - i_src];
  }

  return i;
}

STATIC_FUNCTION int print_floating_point_number(char buffer[32], double number, int integral_width, int pad_zero, int frac_width)
{
  char num[32];
  int num_i = 0;

  int add_minus = 0;
  int exponent = 0;

  int i = 0;

  int auto_width = 0;

  if (frac_width == -1)
  {
    auto_width = 1;
    frac_width = 6;
  }

  if (frac_width > 18)
  {
    frac_width = 18;
  }

  union {
    double f;
    uint64_t i;
  } u;

  u.f = number;

  if (u.i & 0x8000000000000000ULL) /* sign bit */
  {
    add_minus = 1;
    u.i &= ~0x8000000000000000ULL; /* clear sign bit */
    number = u.f;
  }

  if (number != 0)
  {
    if (number > 1.0e6 || number < 1.0e-6)
    {
      /* scientific */
      if (number >= 10.0)
      {
        while (number >= 10.0)
        {
          number /= 10.0;
          exponent++;
        }
      }
      else
      {
        while (number < 1.0)
        {
          number *= 10.0;
          exponent--;
        }
      }
    }
  }

  {
    long long integer_part = (long long)number;
    num_i = print_number(num, integer_part, 0, 0);

    if (add_minus)
      buffer[i++] = '-';

    for (int i_src = 0; i_src < num_i; i_src++)
    {
      buffer[i++] = num[i_src];
    }

    buffer[i++] = '.';

    if (frac_width > 0)
    {
      double frac = number - integer_part;
      double frac_multiply = 1.0;
      for (int i_mul = 0; i_mul < frac_width; i_mul++)
        frac_multiply *= 10.0;

      double frac_multiplied = frac * frac_multiply;
      unsigned long long fractional_part = (unsigned long long)frac_multiplied;

      /* round it according to next digit */
      if ((frac_multiplied - fractional_part) >= 0.5)
      {
        fractional_part++;
      }

      num_i = print_number(num, fractional_part, 1, 0);
      for (int i_zero = num_i; i_zero < frac_width; i_zero++)
      {
        buffer[i++] = '0';
      }
      for (int i_src = 0; i_src < num_i; i_src++)
      {
        buffer[i++] = num[i_src];
      }

      if (auto_width > 0)
      {
        /* remove zeros at the end */
        int pos = i - 1; /* last characted */
        while (pos > 1 && buffer[pos] == '0' && buffer[pos - 1] != '.')
        {
          buffer[pos] = '\0';
          i = pos;
          pos--;
        }
      }
    }
  }

  if (exponent != 0)
  {
    buffer[i++] = 'e';

    num_i = print_number(num, exponent, 0, 0);
    for (int i_src = 0; i_src < num_i; i_src++)
    {
      buffer[i++] = num[i_src];
    }
  }

  return i;
}

STATIC_FUNCTION ssize_t platform_write_stream(io_stream_t stream, char *tmp, size_t size)
{
#ifdef _MSC_VER
  return fwrite(tmp, 1, size, stream);
#else
  return write(stream, tmp, size);
#endif
}

STATIC_FUNCTION void impl_empty_tmp(int mode, io_stream_t stream, char *buffer, size_t buffer_size, long long *pnum_bytes, char *tmp, int *ptmp_count)
{
  if (mode)
  {
    if (buffer && (*pnum_bytes + 1 < buffer_size)) // 1 byte reserved for '\0'
    {
      size_t write_len = MIN_MACRO(*ptmp_count, buffer_size - *pnum_bytes - 1);
      memory_copy(&buffer[*pnum_bytes], tmp, write_len);
      buffer[*pnum_bytes + write_len] = '\0';
    }
  }
  else
  {
    platform_write_stream(stream, tmp, *ptmp_count);
  }
  *pnum_bytes += *ptmp_count;
  *ptmp_count = 0;
}

STATIC_FUNCTION long long format_impl(int mode, io_stream_t stream, char *buffer, size_t buffer_size,  const char *fmt, va_list list)
{
  char tmp[1024];
  int tmp_count = 0;

  long long num_bytes = 0;

  const char *s = fmt;

  while (*s)
  {
    if (*s == '%')
    {
      int zero_pad = 0;
      int width = -1; /* -1 = width undefined */
      int frac_width = -1; /* -1 = frac_width undefined */
      int format = 0; // 0 signed, 1 unsigned, 2 hex, 3 hex uppercase
      int add_hex_prefix = 0;
      unsigned long long number = 0;
      double floating_number = 0.0;

      s++;
      if (*s == '0')
      {
        zero_pad = 1;
        if (width == -1)
          width = 0;
        s++;
      }

      while (*s >= '0' && *s <= '9')
      {
        if (width == -1)
          width = 0;
        width *= 10;
        width += (*s - '0');
        s++;
      }

      if (*s == '.')
      {
        s++;
        while (*s >= '0' && *s <= '9')
        {
          if (frac_width == -1)
            frac_width = 0;
          frac_width *= 10;
          frac_width += (*s - '0');
          s++;
        }
      }

      if (*s == 'd')
        number = va_arg(list, int);
      else if (*s == 'l' && s[1] == 'd')
      {
        number = va_arg(list, long int);
        s += 1;
      }
      else if (*s == 'l' && s[1] == 'l' && s[2] == 'd')
      {
        number = va_arg(list, long long int);
        s += 2;
      }
      else if (*s == 'u' || *s == 'x' || *s == 'X')
      {
        format = *s == 'u' ? 1 : *s == 'x' ? 2 : 3;
        number = va_arg(list, unsigned int);
      }
      else if (*s == 'l' && (s[1] == 'u' || s[1] == 'x' || s[1] == 'X'))
      {
        format = s[1] == 'u' ? 1 : s[1] == 'x' ? 2 : 3;
        number = va_arg(list, unsigned long int);
        s += 1;
      }
      else if (*s == 'l' && s[1] == 'l' && (s[2] == 'u' || s[2] == 'x' || s[2] == 'X'))
      {
        format = s[2] == 'u' ? 1 : s[2] == 'x' ? 2 : 3;
        number = va_arg(list, unsigned long long int);
        s += 2;
      }
      else if (*s == 'p')
      {
        format = 2;
        number = va_arg(list, unsigned long long int);
        add_hex_prefix = 1;
      }
      else if (*s == 'f')
      {
        format = 4;
        floating_number = va_arg(list, double);
      }
      else if (*s == 'l' && s[1] == 'f')
      {
        format = 4;
        floating_number = va_arg(list, double);
        s += 1;
      }
      else if (*s == 's')
      {
        const char *str = va_arg(list, const char *);
        if (!str)
          str = "(NULL)";

        while (*str)
        {
          tmp[tmp_count++] = *str++;
          if (tmp_count == sizeof(tmp))
          {
            impl_empty_tmp(mode, stream, buffer, buffer_size, &num_bytes, tmp, &tmp_count);
          }
        }
        s++;
        continue;
      }
      else if (*s == '%')
      {
        tmp[tmp_count++] = '%';
        if (tmp_count == sizeof(tmp))
        {
          impl_empty_tmp(mode, stream, buffer, buffer_size, &num_bytes, tmp, &tmp_count);
        }
        s++;
        continue;
      }
      else
      {
      }

      s++;

      int num_i;
      char num[32];

      if (format < 4)
        num_i = print_number(num, number, format, add_hex_prefix);
      else
        num_i = print_floating_point_number(num, floating_number, -1, 0, frac_width);

      const char *src = num;
      int src_len = num_i;
      if (width != -1)
      {
        if (num_i > width)
        {
          src = &num[num_i - width]; /* truncate the number */
          src_len = width;
        }
        else if (num_i < width)
        {
          /* pad */
          for (int i = num_i; i < width; i++)
          {
            tmp[tmp_count++] = zero_pad ? '0' : ' ';
            if (tmp_count == sizeof(tmp))
            {
              impl_empty_tmp(mode, stream, buffer, buffer_size, &num_bytes, tmp, &tmp_count);
            }
          }
        }
      }

      for (int i = 0; i < src_len; i++)
      {
        tmp[tmp_count++] = *src++;
        if (tmp_count == sizeof(tmp))
        {
          impl_empty_tmp(mode, stream, buffer, buffer_size, &num_bytes, tmp, &tmp_count);
        }
      }
    }
    else
    {
      tmp[tmp_count++] = *s;
      if (tmp_count == sizeof(tmp))
      {
        impl_empty_tmp(mode, stream, buffer, buffer_size, &num_bytes, tmp, &tmp_count);
      }

      s++;
    }
  }

  if (tmp_count > 0)
  {
    impl_empty_tmp(mode, stream, buffer, buffer_size, &num_bytes, tmp, &tmp_count);
  }

  return num_bytes;
}

STATIC_FUNCTION bool stream_has_data(io_stream_t stream)
{
#ifdef _MSC_VER
  if (feof(stream))
    return false;

  return true;
#else
  fd_set fds;
  FD_ZERO(&fds);
  FD_SET(stream, &fds);

  struct timeval tv = {0, 0};

  int ret = select(1, &fds, NULL, NULL, &tv);

  if (ret == -1)
  {
    return false;
  }
  else if (ret == 0)
  {
    /* no data */
    return false;
  }
#endif
  return true;
}

STATIC_FUNCTION void flush_stream(io_stream_t stream)
{
#ifdef _MSC_VER
  fflush(stream);
#else
  fsync(stream);
#endif
}

STATIC_FUNCTION long long print_stream(io_stream_t stream, const char *fmt, ...)
{
  va_list list;
  va_start(list, fmt);
  long long ret = format_impl(0, stream, NULL, 0, fmt, list);
  va_end(list);
  return ret;
}

STATIC_FUNCTION long long print_string(char *buffer, size_t buffer_size, const char *fmt, ...)
{
  va_list list;
  va_start(list, fmt);
  long long ret = format_impl(1, 0, buffer, buffer_size, fmt, list);
  va_end(list);
  return ret;
}

STATIC_FUNCTION long long print_string_or_stream(int mode, io_stream_t stream, char *buffer, size_t buffer_size, const char *fmt, ...)
{
  va_list list;
  va_start(list, fmt);
  long long ret = format_impl(mode, stream, buffer, buffer_size, fmt, list);
  va_end(list);
  return ret;
}

STATIC_FUNCTION char *read_file_string(const char *filename, long long *size_out)
{
#ifdef _MSC_VER
  FILE *f = fopen(filename, "rb");
  if (!f)
    return NULL;
  fseek(f, 0, SEEK_END);
  long size = ftell(f);
  fseek(f, 0, SEEK_SET);

  if (size_out)
    *size_out = size;

  char *buf = (char *)MALLOC(size + 1);
  ssize_t num_bytes = fread(buf, 1, size, f);
  if (num_bytes != size)
  {
    FREE(buf);
    fclose(f);
    return NULL;
  }

  buf[size] = '\0';
  fclose(f);
#else
  int fd = open(filename, O_RDONLY);
  if (fd < 0)
    return NULL;

  struct stat st;
  if (fstat(fd, &st) != 0 || !S_ISREG(st.st_mode))
  {
    close(fd);
    return NULL;
  }

  off_t pos = lseek(fd, 0, SEEK_END);
  lseek(fd, 0, SEEK_SET);

  if (pos == -1)
  {
    close(fd);
    return NULL;
  }

  if (size_out)
    *size_out = pos;

  char *buf = (char *)MALLOC(pos + 1);
  ssize_t num_bytes = read(fd, buf, pos);
  if (num_bytes != pos)
  {
    FREE(buf);
    close(fd);
    return NULL;
  }

  buf[pos] = '\0';
  close(fd);
#endif
  return buf;
}

/**
 * vec_t
 *
 * A resizable array (vector) type.
 * Public API are macros which can be used with different element types
 */

typedef struct vec_t
{
  unsigned char *storage_;
  size_t size_;
  size_t storage_size_;
} vec_t;

#define VEC_ALLOC(type, size, storage_size) vec_alloc(sizeof(type) * (size), sizeof(type) * (storage_size))
#define VEC_FREE(v) vec_free((v))
#define VEC_RESIZE(type, v, size) vec_resize((v), size * sizeof(type))
#define VEC_NTH(type, x, i) (((type *)((x)->storage_))[(i)])
#define VEC_SIZE(type, v) ((v)->size_ / sizeof(type))
#define VEC_PUSHBACK(type, v, o) do { vec_reserve_pushback(v, sizeof(type)); VEC_NTH(type, v, v->size_/sizeof(type)) = o; v->size_ += sizeof(type); } while (0)
#define VEC_FILL(type, v, count, val) do { vec_reserve_min(v, count * sizeof(type)); v->size_ = (count) * sizeof(type); for (size_t impl_i = 0; impl_i < (count); impl_i++) VEC_NTH(type, v, impl_i) = (val); } while (0)

STATIC_FUNCTION vec_t *vec_alloc(size_t size, size_t storage_size)
{
  vec_t *v = (vec_t *)MALLOC(sizeof(vec_t));
  v->size_ = size;
  v->storage_size_ = storage_size >= size ? storage_size : size;
  v->storage_ = (unsigned char *)MALLOC(v->storage_size_);
  return v;
}

STATIC_FUNCTION void vec_free(vec_t *v)
{
  FREE(v->storage_);
  FREE(v);
}

STATIC_FUNCTION void vec_reserve_min(vec_t *v, size_t count)
{
  if (v->storage_size_ < count)
  {
    /* reallocate */
    unsigned char *prev_storage = v->storage_;

    v->storage_size_ = count;
    v->storage_ = (unsigned char *)MALLOC(v->storage_size_);
    memory_copy(v->storage_, prev_storage, v->size_);

    FREE(prev_storage);
  }
}

STATIC_FUNCTION void vec_resize(vec_t *v, size_t size)
{
  vec_reserve_min(v, size);
  v->size_ = size;
}

STATIC_FUNCTION void vec_reserve_pushback(vec_t *v, size_t bytes)
{
  if (v->size_ + bytes > v->storage_size_)
  {
    vec_reserve_min(v, v->storage_size_ * 2);
  }
}

#endif // _BASICSLIB_H_

