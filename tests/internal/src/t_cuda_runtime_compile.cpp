// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

#include <cuda_runtime_api.h>

#include "../../cuda_test_helpers.hpp"

#ifdef __CUDACC__
#error blt::cuda_runtime should not change C++ sources to CUDA language sources.
#endif

int main()
{
  return blt::test::require_cuda_device("t_cuda_runtime_compile") ? 0 : 1;
}
