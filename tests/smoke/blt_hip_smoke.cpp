// Copyright (c) Lawrence Livermore National Security, LLC and other
// BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

//-----------------------------------------------------------------------------
//
// file: blt_hip_smoke.cpp
//
//-----------------------------------------------------------------------------

#include <cstdio>
#include "hip/hip_runtime.h"

__device__ const char STR[] = "HELLO WORLD!";
const int STR_LENGTH = 12;

__global__ void hello()
{
  printf("%c\n", STR[threadIdx.x % STR_LENGTH]);
}

int main()
{
  hipError_t rc = hipSuccess;
  int num_threads = STR_LENGTH;
  int num_blocks = 1;

  hipLaunchKernelGGL((hello), dim3(num_blocks), dim3(num_threads),0,0);
  rc = hipGetLastError();
  if (rc != hipSuccess) 
  {
    fprintf(stderr,"[HIP ERROR]: %s\n", hipGetErrorString(rc));
    return -1;
  }

  rc = hipDeviceSynchronize(); 
  if (rc != hipSuccess) 
  {
    fprintf(stderr, "[HIP ERROR]: %s\n", hipGetErrorString(rc));
    return -1;
  }

  return 0;
}


