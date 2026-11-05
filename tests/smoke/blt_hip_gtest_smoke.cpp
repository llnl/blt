// Copyright (c) Lawrence Livermore National Security, LLC and other
// BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

//-----------------------------------------------------------------------------
//
// file: blt_hip_smoke.cpp
//
//-----------------------------------------------------------------------------
#include "gtest/gtest.h"
#include "hip/hip_runtime.h"

__device__ const char STR[] = "HELLO WORLD!";
const int STR_LENGTH = 12;

__global__ void hello()
{
  printf("%c\n", STR[threadIdx.x % STR_LENGTH]);
}

//------------------------------------------------------------------------------
// Simple smoke test for gtest+HIP
//------------------------------------------------------------------------------
TEST(blt_hip_gtest_smoke,basic_assert_example)
{
  hipError_t rc;
  int num_threads = STR_LENGTH;
  int num_blocks = 1;
  hipLaunchKernelGGL((hello), dim3(num_blocks), dim3(num_threads),0,0);
  rc = hipGetLastError();
  EXPECT_EQ(rc,hipSuccess) << "[HIP ERROR]: " << hipGetErrorString(rc) << "\n";

  rc = hipDeviceSynchronize();
  EXPECT_EQ(rc,hipSuccess) << "[HIP ERROR]: " << hipGetErrorString(rc) << "\n";
}
