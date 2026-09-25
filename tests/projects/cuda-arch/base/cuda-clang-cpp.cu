#include <stdio.h>
#include <string>
#include <cuda.h>
#include "cuda-clang-cpp.cuh"

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

__global__ void kernel() {
  const char arch[] = STR(__CUDA_ARCH__);
  printf("Current arch =  %s", arch);
}

void run_kernel() {
  kernel<<<1, 1>>>();
  cudaDeviceSynchronize();
}
