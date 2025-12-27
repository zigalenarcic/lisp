
#include <stdio.h>

#ifdef _MSC_VER
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT
#endif

DLLEXPORT int test(int a, int b)
{
  printf("In %s %d %d\n", __func__, a, b);

  return a + b;
}

DLLEXPORT int test2(int a, int b, int c, int d)
{
  printf("In %s %d %d %d %d\n", __func__, a, b, c, d);

  return a + b + c + d;
}

DLLEXPORT int test_float(double a, float b)
{
  printf("In %s %f %f\n", __func__, a, b);

  return a + b;
}

DLLEXPORT int test_float2(double a, double b, int c, double d)
{
  printf("In %s %f %f %d %f\n", __func__, a, b, c, d);

  return a + b + c + d;
}

DLLEXPORT long long int test_ptr(int *a, unsigned long long *b, char *c, float *d)
{
  printf("In %s %p %p %p %p\n", __func__, a, b, c, d);
  printf("In %s contents: %d %llu \"%s\" %f\n", __func__, a[0], b[0], c, d[0]);

  return a[0] + b[0] + c[0] + (int)d[0];
}

DLLEXPORT int func1(float a0, float a1, float a2, float a3, float a4, float a5, float a6, float a7, float a8, float a9, float a10)
{
  printf("In %s %f %f %f %f %f %f %f %f %f %f %f\n", __func__, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);

  return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9 + a10;
}

DLLEXPORT int func2(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8)
{
  printf("In %s %d %d %d %d %d %d %d %d %d\n", __func__, a0, a1, a2, a3, a4, a5, a6, a7, a8);

  return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8;
}

DLLEXPORT int func3(int a0, float a1, float a2, float a3, float a4, float a5, float a6, float a7, float a8, float a9, int a10, float a11, int a12, int a13, int a14, int a15, int a16, float a17)
{
  printf("In %s %d %f %f %f %f %f %f %f %f %f %d %f %d %d %d %d %d %f\n", __func__, a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17);

  return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9 + a10 + a11 + a12 + a13 + a14 + a15 + a16 + a17;
}

