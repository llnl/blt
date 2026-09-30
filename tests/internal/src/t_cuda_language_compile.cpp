// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

#include <cuda_runtime_api.h>

#include "../../cuda_test_helpers.hpp"

#ifndef __CUDACC__
#error blt::cuda should change C++ sources to CUDA language sources.
#endif

__global__ void t_cuda_language_compile_kernel(int *value)
{
  *value = 1;
}

int main()
{
  if (!blt::test::require_cuda_device("t_cuda_language_compile"))
  {
    return 1;
  }

  int *value = nullptr;
  cudaError_t result = cudaMalloc(&value, sizeof(int));
  if (!blt::test::check_cuda_call(result,
                                  "t_cuda_language_compile",
                                  "cudaMalloc"))
  {
    return 1;
  }

  t_cuda_language_compile_kernel<<<1, 1>>>(value);
  result = cudaGetLastError();
  if (!blt::test::check_cuda_call(result,
                                  "t_cuda_language_compile",
                                  "kernel launch"))
  {
    blt::test::check_cuda_call(cudaFree(value),
                               "t_cuda_language_compile",
                               "cudaFree after launch failure");
    return 1;
  }

  result = cudaDeviceSynchronize();
  if (!blt::test::check_cuda_call(result,
                                  "t_cuda_language_compile",
                                  "cudaDeviceSynchronize"))
  {
    blt::test::check_cuda_call(cudaFree(value),
                               "t_cuda_language_compile",
                               "cudaFree after synchronization failure");
    return 1;
  }

  result = cudaFree(value);
  if (!blt::test::check_cuda_call(result,
                                  "t_cuda_language_compile",
                                  "cudaFree"))
  {
    return 1;
  }

  return 0;
}
