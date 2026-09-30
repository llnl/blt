// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
// Note: This is a CUDA example from NVIDIA:
// Obtained from here:
// https://devblogs.nvidia.com/parallelforall/how-query-device-properties-and-handle-errors-cuda-cc/
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//

//-----------------------------------------------------------------------------
//
// file: blt_cuda_runtime_smoke.cpp
//
//-----------------------------------------------------------------------------

#include <iostream>
#include "cuda_runtime_api.h"
#include <stdio.h>

#include "../cuda_test_helpers.hpp"

int main()
{
  int nDevices = 0;
  if (!blt::test::require_cuda_device("blt_cuda_runtime_smoke", &nDevices))
  {
    return 1;
  }

  for (int i = 0; i < nDevices; i++)
  {
    cudaDeviceProp prop;
    int memoryClockRate;
    if (!blt::test::check_cuda_call(cudaGetDeviceProperties(&prop, i),
                                    "blt_cuda_runtime_smoke",
                                    "cudaGetDeviceProperties"))
    {
      return 1;
    }

#if CUDART_VERSION >= 13000
    if (!blt::test::check_cuda_call(
          cudaDeviceGetAttribute(&memoryClockRate,
                                 cudaDevAttrMemoryClockRate,
                                 i),
          "blt_cuda_runtime_smoke",
          "cudaDeviceGetAttribute(cudaDevAttrMemoryClockRate)"))
    {
      return 1;
    }
#else
    memoryClockRate = prop.memoryClockRate;
#endif

    printf("Device Number: %d\n", i);
    printf("  Device name: %s\n", prop.name);
    printf("  Memory Clock Rate (KHz): %d\n",
           memoryClockRate);
    printf("  Memory Bus Width (bits): %d\n",
           prop.memoryBusWidth);
    printf("  Peak Memory Bandwidth (GB/s): %f\n\n",
           2.0*memoryClockRate*(prop.memoryBusWidth/8)/1.0e6);
  }

  return 0;
}
