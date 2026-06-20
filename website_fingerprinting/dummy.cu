#include <cuda.h>

/*******************************************************************************
 * Do nothing, simply conduct the context switch
 ******************************************************************************/
__global__ void 
dummy()
{
  uint64_t clk0;
  uint64_t clk1;
  clk0 = clock64();
  clk1 = clock64();
  while (1) {
    clk0 = clock64();
    clk1 = clock64();
  }
}

int 
main()
{
  dummy<<<1, 1>>>();
  cudaDeviceSynchronize();
}

