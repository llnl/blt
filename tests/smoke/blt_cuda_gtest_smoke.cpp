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

#include "gtest/gtest.h"
#include "../cuda_test_helpers.hpp"

__device__ const char *STR = "HELLO WORLD!";
const char STR_LENGTH = 12;

__global__ void hello()
{
  printf("%c\n", STR[threadIdx.x % STR_LENGTH]);
}

//------------------------------------------------------------------------------
// Simple smoke test for gtest+CUDA
//------------------------------------------------------------------------------
TEST(blt_cuda_gtest_smoke,basic_assert_example)
{
  int num_threads = STR_LENGTH;
  int num_blocks = 1;
  hello<<<num_blocks,num_threads>>>();
  ASSERT_EQ(cudaSuccess, cudaGetLastError());
  ASSERT_EQ(cudaSuccess, cudaDeviceSynchronize());
}

int main(int argc, char** argv)
{
  if (!blt::test::require_cuda_device("blt_cuda_gtest_smoke"))
  {
    return 1;
  }

  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
