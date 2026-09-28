// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

#include "Parent.hpp"
#include <string.h>

#if defined(__clang__)
// Clang's CUDA runtime omits this device symbol, which is referenced by
// Parent's pure-virtual device vtable.
extern "C" __device__ void __cxa_pure_virtual()
{
  __builtin_trap();
}
#endif

__host__ __device__ Parent::Parent(const char *id, int order)
  : m_gpuParent(NULL)
  , m_gpuExtractedParents(NULL)
{}

__global__ void kernelDelete(Parent** myGpuParent) {}
__global__ void kernelDeleteExtracted(Parent*** gpuExtractedParents) {}
