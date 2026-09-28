// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

//-----------------------------------------------------------------------------
//
// file: blt_cuda_version_smoke.cpp
//
//-----------------------------------------------------------------------------

#include <iostream>
#include <string>
#include "cuda_runtime_api.h"

#include "../cuda_test_helpers.hpp"

int main()
{
  int         driverVersion  = 0;
  int         runtimeVersion = 0;
  cudaError_t error_id;

  if (!blt::test::require_cuda_device("blt_cuda_version_smoke"))
  {
    return 1;
  }

  error_id = cudaDriverGetVersion(&driverVersion);
  if (!blt::test::check_cuda_call(error_id,
                                  "blt_cuda_version_smoke",
                                  "cudaDriverGetVersion"))
  {
    return 1;
  }
  std::cout << "CUDA driver version: " << driverVersion << std::endl;

  error_id = cudaRuntimeGetVersion(&runtimeVersion);
  if (!blt::test::check_cuda_call(error_id,
                                  "blt_cuda_version_smoke",
                                  "cudaRuntimeGetVersion"))
  {
    return 2;
  }
  std::cout << "CUDA runtime version: " << runtimeVersion << std::endl;

  return 0;
}
