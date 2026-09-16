// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

#include <cuda_runtime_api.h>

#ifdef __CUDACC__
#error blt::cuda_runtime should not change C++ sources to CUDA language sources.
#endif

int main()
{
  int device_count = 0;
  cudaError_t result = cudaGetDeviceCount(&device_count);
  return result == cudaSuccess || result == cudaErrorNoDevice ? 0 : 1;
}
