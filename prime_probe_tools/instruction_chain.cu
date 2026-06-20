#include <cuda.h>

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
#define PRAGMA_UNROLL(x) _Pragma(TOSTRING(unroll x))

#define NUM1 6000
#define NUM2 6000

__device__ __noinline__ uint32_t
dummy_func_0x0(int flag)
{
  uint32_t i;
  uint64_t sum = 0;

  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();

    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }

  return sum;
}

__device__ __noinline__ uint32_t
dummy_func_0x1(int flag)
{
  uint32_t i;
  uint64_t sum = 1;

  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();

    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }

  return sum;
}

__device__ __noinline__ uint32_t
dummy_func_0x2(int flag)
{
  uint32_t i;
  uint64_t sum = 2;

  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();

    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }

  return sum;
}

__device__ __noinline__ uint32_t
dummy_func_0x3(int flag)
{
  uint32_t i;
  uint64_t sum = 3;

  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();

    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }

  return sum;
}

__device__ __noinline__ uint32_t
dummy_func_0x4(int flag)
{
  uint32_t i;
  uint64_t sum = 4;

  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();

    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }

  return sum;
}

__device__ __noinline__ uint32_t
dummy_func_0x5(int flag)
{
  uint32_t i;
  uint64_t sum = 5;

  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();

    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }

  return sum;
}

__device__ __noinline__ uint32_t
dummy_func_0x6(int flag)
{
  uint32_t i;
  uint64_t sum = 6;

  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();

    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }

  return sum;
}

__device__ __noinline__ uint32_t
dummy_func_0x7(int flag)
{
  uint32_t i;
  uint64_t sum = 7;

  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();

    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }

  return sum;
}

__device__ __noinline__ uint32_t 
dummy_func_0x8(int flag)
{
  uint32_t i;
  uint64_t sum = 8;
  
  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();
    
    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }
  
  return sum;
}

__device__ __noinline__ uint32_t 
dummy_func_0x9(int flag)
{
  uint32_t i;
  uint64_t sum = 9;
  
  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();
    
    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }
  
  return sum;
}

__device__ __noinline__ uint32_t 
dummy_func_0xa(int flag)
{
  uint32_t i;
  uint64_t sum = 10;
  
  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();
    
    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }
  
  return sum;
}

__device__ __noinline__ uint32_t 
dummy_func_0xb(int flag)
{
  uint32_t i;
  uint64_t sum = 11;
  
  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();
    
    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }
  
  return sum;
}

__device__ __noinline__ uint32_t 
dummy_func_0xc(int flag)
{
  uint32_t i;
  uint64_t sum = 12;
  
  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();
    
    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }
  
  return sum;
}

__device__ __noinline__ uint32_t 
dummy_func_0xd(int flag)
{
  uint32_t i;
  uint64_t sum = 13;
  
  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();
    
    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }
  
  return sum;
}

__device__ __noinline__ uint32_t 
dummy_func_0xe(int flag)
{
  uint32_t i;
  uint64_t sum = 14;
  
  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();
    
    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }
  
  return sum;
}

__device__ __noinline__ uint32_t 
dummy_func_0xf(int flag)
{
  uint32_t i;
  uint64_t sum = 15;
  
  if (flag) {
    PRAGMA_UNROLL(NUM1)
    for (i = 0; i < NUM1; ++i)
      sum += clock64();
    
    PRAGMA_UNROLL(NUM2)
    for (i = 0; i < NUM2; ++i)
      sum -= clock64();
  }
  
  return sum;
}




