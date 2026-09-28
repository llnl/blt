// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

#ifndef BLT_TESTS_CUDA_TEST_HELPERS_HPP
#define BLT_TESTS_CUDA_TEST_HELPERS_HPP

#include <cuda_runtime_api.h>

#include <iostream>

namespace blt
{
namespace test
{

inline bool require_cuda_device(const char* test_name,
                                int* device_count_out = nullptr)
{
  int device_count = 0;
  const cudaError_t result = cudaGetDeviceCount(&device_count);

  if (result == cudaErrorNoDevice ||
      (result == cudaSuccess && device_count == 0))
  {
    std::cerr << "ERROR: " << test_name
              << " requires at least one CUDA-capable device, but no CUDA "
                 "devices were found. Run this test in a GPU allocation and "
                 "verify that "
                 "CUDA_VISIBLE_DEVICES exposes a device."
              << std::endl;
    return false;
  }

  if (result != cudaSuccess)
  {
    std::cerr << "ERROR: " << test_name
              << " requires an accessible CUDA device, but cudaGetDeviceCount "
                 "failed: "
              << cudaGetErrorString(result)
              << ". Verify the GPU allocation, CUDA driver, and "
                 "CUDA_VISIBLE_DEVICES."
              << std::endl;
    return false;
  }

  if (device_count_out != nullptr)
  {
    *device_count_out = device_count;
  }

  return true;
}

} // namespace test
} // namespace blt

#endif
