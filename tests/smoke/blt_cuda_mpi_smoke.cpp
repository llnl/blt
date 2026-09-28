// Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
// other BLT Project Developers. See the top-level LICENSE file for details
//
// SPDX-License-Identifier: (BSD-3-Clause)

//-----------------------------------------------------------------------------
//
// file: blt_cuda_mpi_smoke.cpp
//
//-----------------------------------------------------------------------------

#include <cuda_runtime.h>
#include <iostream>
#include <mpi.h>
#include <stdio.h>
#include <string>

#include "../cuda_test_helpers.hpp"

__global__ void hello(int rank) { printf("Hello from MPI rank %d\n", rank); }

int main(int argc, char **argv) {
  MPI_Init(&argc, &argv);

  int rank = -1;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  const std::string testName =
    "blt_cuda_mpi_smoke rank " + std::to_string(rank);
  bool localSuccess = blt::test::require_cuda_device(testName.c_str());
  if (localSuccess)
  {
    hello<<<1, 1>>>(rank);
    localSuccess = blt::test::check_cuda_call(cudaGetLastError(),
                                               testName.c_str(),
                                               "hello kernel launch");
    if (localSuccess)
    {
      localSuccess = blt::test::check_cuda_call(cudaDeviceSynchronize(),
                                                 testName.c_str(),
                                                 "cudaDeviceSynchronize");
    }
  }

  int localSuccessValue = localSuccess ? 1 : 0;
  int globalSuccess = 0;
  MPI_Allreduce(&localSuccessValue, &globalSuccess, 1, MPI_INT, MPI_MIN,
                MPI_COMM_WORLD);

  MPI_Finalize();
  return globalSuccess ? 0 : 1;
}
