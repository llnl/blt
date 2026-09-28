// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

#include <new>
#include "Parent.hpp"
#include "Child.hpp"
#include "../../../cuda_test_helpers.hpp"

__global__ void kernelApply(Parent** myGpuParent)
{
  double *input = new double[4];
  input[0] = 1.0;
  input[1] = 2.0;
  input[2] = 3.0;
  input[3] = 4.0;
  (*myGpuParent)->Evaluate(input);
}

int main(void)
{
  if (!blt::test::require_cuda_device("t_cuda_device_call_from_kernel"))
  {
    return 1;
  }

  Child *c = new Child(0.0, 0.0, 0.0, 0.0);
  kernelApply<<<1, 1>>>(c->m_gpuParent);
  if (!blt::test::check_cuda_call(cudaGetLastError(),
                                  "t_cuda_device_call_from_kernel",
                                  "kernelApply launch"))
  {
    return 1;
  }
  if (!blt::test::check_cuda_call(cudaDeviceSynchronize(),
                                  "t_cuda_device_call_from_kernel",
                                  "cudaDeviceSynchronize"))
  {
    return 1;
  }
  return 0;
}
