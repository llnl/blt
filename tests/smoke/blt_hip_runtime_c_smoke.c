// Copyright (c) Lawrence Livermore National Security, LLC and other
// BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

//-----------------------------------------------------------------------------
//
// file: blt_hip_runtime_c_smoke.c
//
//-----------------------------------------------------------------------------

#include <stdio.h>

#include "hip/hip_runtime_api.h"

int main()
{
  hipError_t rc = hipSuccess;     
  int nDevices = 0;

  rc = hipGetDeviceCount(&nDevices);
  if (rc != hipSuccess)
  {
    fprintf(stderr, "[HIP ERROR]: %s", hipGetErrorString(rc));
    return -1;
  }

  for (int i = 0; i < nDevices; i++)
  {
    hipDeviceProp_t prop;
    rc = hipGetDeviceProperties(&prop, i);
    if (rc != hipSuccess)
    {
      fprintf(stderr, "[HIP ERROR]: %s", hipGetErrorString(rc));
      return -1;
    }

    printf("Device Number: %d\n", i);
    printf("  Device name: %s\n", prop.name);
    printf("  Memory Clock Rate (KHz): %d\n",
           prop.memoryClockRate);
    printf("  Memory Bus Width (bits): %d\n",
           prop.memoryBusWidth);
    printf("  Peak Memory Bandwidth (GB/s): %f\n\n",
           2.0*prop.memoryClockRate*(prop.memoryBusWidth/8)/1.0e6);
  }

  return 0;
}
