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

__global__ void hello(int rank) { printf("Hello from MPI rank %d\n", rank); }

int main(int argc, char **argv) {
  MPI_Init(&argc, &argv);

  int rank = -1;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  hello<<<1, 1>>>(rank);
  cudaError_t status = cudaDeviceSynchronize();

  int localSuccess = status == cudaSuccess;
  int globalSuccess = 0;
  MPI_Allreduce(&localSuccess, &globalSuccess, 1, MPI_INT, MPI_MIN,
                MPI_COMM_WORLD);

  if (!localSuccess) {
    std::cerr << "MPI rank " << rank << ": " << cudaGetErrorString(status)
              << std::endl;
  }

  MPI_Finalize();
  return globalSuccess ? 0 : 1;
}
