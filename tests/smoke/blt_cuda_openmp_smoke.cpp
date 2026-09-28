// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
// Note: Parts of this are a CUDA Hello world example from NVIDIA:
// Obtained from here: https://developer.nvidia.com/cuda-education
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//

//-----------------------------------------------------------------------------
//
// file: blt_cuda_openmp_smoke.cpp
//
//-----------------------------------------------------------------------------

#include <iostream>
#include <omp.h>
#include <stdio.h>

#include "../cuda_test_helpers.hpp"

__device__ const char *STR = "HELLO WORLD!";
const char STR_LENGTH = 12;

__global__ void hello()
{
  printf("%c\n", STR[threadIdx.x % STR_LENGTH]);
}

int main()
{
  if (!blt::test::require_cuda_device("blt_cuda_openmp_smoke"))
  {
    return 1;
  }

  // CUDA smoke test
  int num_threads = STR_LENGTH;
  int num_blocks = 1;
  hello<<<num_blocks,num_threads>>>();
  cudaError_t result = cudaGetLastError();
  if (!blt::test::check_cuda_call(result,
                                  "blt_cuda_openmp_smoke",
                                  "hello kernel launch"))
  {
    return 1;
  }

  result = cudaDeviceSynchronize();
  if (!blt::test::check_cuda_call(result,
                                  "blt_cuda_openmp_smoke",
                                  "cudaDeviceSynchronize"))
  {
    return 1;
  }

  // OpenMP smoke test
  #pragma omp parallel
  {
    int thId = omp_get_thread_num();
    int thNum = omp_get_num_threads();
    int thMax = omp_get_max_threads();

    #pragma omp critical
    std::cout <<"\nMy thread id is: " << thId
              <<"\nNum threads is: " << thNum
              <<"\nMax threads is: " << thMax
              << std::endl;
  }

  return 0;
}
