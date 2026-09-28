// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
// Note: This is a CUDA Hello world example from NVIDIA:
// Obtained from here: https://developer.nvidia.com/cuda-education
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//

//-----------------------------------------------------------------------------
//
// file: blt_cuda_smoke.cpp
//
//-----------------------------------------------------------------------------

#include <iostream>
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
  if (!blt::test::require_cuda_device("blt_cuda_smoke"))
  {
    return 1;
  }

  int num_threads = STR_LENGTH;
  int num_blocks = 1;
  hello<<<num_blocks,num_threads>>>();
  cudaError_t result = cudaGetLastError();
  if (result != cudaSuccess)
  {
    std::cerr << cudaGetErrorString(result) << std::endl;
    return 1;
  }

  result = cudaDeviceSynchronize();
  return result == cudaSuccess ? 0 : 1;
}
