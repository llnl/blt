// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

#include <cuda_runtime_api.h>

#ifndef __CUDACC__
#error blt::cuda should change C++ sources to CUDA language sources.
#endif

__global__ void t_cuda_language_compile_kernel(int *value)
{
  *value = 1;
}

int main()
{
  int *value = nullptr;
  cudaError_t result = cudaMalloc(&value, sizeof(int));
  if (result != cudaSuccess)
  {
    return result == cudaErrorNoDevice ? 0 : 1;
  }

  t_cuda_language_compile_kernel<<<1, 1>>>(value);
  result = cudaDeviceSynchronize();
  cudaFree(value);

  return result == cudaSuccess ? 0 : 1;
}
