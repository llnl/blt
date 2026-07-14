# Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)

#------------------------------------------------------------------------------
# Example host-config file for a cluster on a TOSS4 NVidia platform (e.g. matrix) at LLNL
#------------------------------------------------------------------------------
#
# This file provides CMake with paths / details for:
#  C,C++, & Fortran compilers + MPI + CUDA + OpenMP
# 
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Compilers
#------------------------------------------------------------------------------
set(CMAKE_C_COMPILER "/usr/tce/packages/clang/clang-19.1.3-magic/bin/clang" CACHE PATH "")
set(CMAKE_CXX_COMPILER "/usr/tce/packages/clang/clang-19.1.3-magic/bin/clang++" CACHE PATH "")
set(CMAKE_Fortran_COMPILER "/usr/tce/packages/gcc/gcc-13.3.1/bin/gfortran" CACHE PATH "")

set(CMAKE_C_FLAGS "-fPIC" CACHE STRING "")
set(CMAKE_CXX_FLAGS "-fPIC" CACHE STRING "")
set(CMAKE_Fortran_FLAGS "-fPIC" CACHE STRING "")

set(ENABLE_FORTRAN ON CACHE BOOL "")

set(BLT_EXE_LINKER_FLAGS " -Xlinker -rpath -Xlinker /usr/tce/packages/clang/clang-19.1.3-magic/lib" CACHE STRING "Adds a missing libstdc++ rpath")

#------------------------------------------------------------------------------
# MPI
#------------------------------------------------------------------------------

set(MPI_C_COMPILER "/usr/tce/packages/mvapich2/mvapich2-2.3.7-clang-19.1.3/bin/mpicc" CACHE PATH "")

set(MPI_CXX_COMPILER "/usr/tce/packages/mvapich2/mvapich2-2.3.7-clang-19.1.3/bin/mpicxx" CACHE PATH "")

set(MPI_Fortran_COMPILER "/usr/tce/packages/mvapich2/mvapich2-2.3.7-clang-19.1.3/bin/mpif90" CACHE PATH "")

set(MPIEXEC_EXECUTABLE "/usr/bin/srun" CACHE PATH "")

set(MPIEXEC_NUMPROC_FLAG "-n" CACHE STRING "")

set(ENABLE_MPI ON CACHE BOOL "")

#------------------------------------------------
# Cuda
#------------------------------------------------

set(CUDAToolkit_ROOT "/usr/tce/packages/cuda/cuda-12.9.1" CACHE PATH "")

set(CMAKE_CUDA_COMPILER "${CUDAToolkit_ROOT}/bin/nvcc" CACHE PATH "")

set(CMAKE_CUDA_HOST_COMPILER "${CMAKE_CXX_COMPILER}" CACHE PATH "")

set(CMAKE_CUDA_ARCHITECTURES "90" CACHE STRING "")

set(CMAKE_CUDA_FLAGS "" CACHE STRING "")

set(ENABLE_CUDA ON CACHE BOOL "")

set(CMAKE_CUDA_SEPARABLE_COMPILATION ON CACHE BOOL "")

set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -restrict --expt-extended-lambda --expt-relaxed-constexpr -Xcompiler=-fPIC " CACHE STRING "" FORCE)

# nvcc does not like gtest's 'pthreads' flag

set(gtest_disable_pthreads ON CACHE BOOL "")

#------------------------------------------------
# OpenMP
#------------------------------------------------

set(ENABLE_OPENMP ON CACHE BOOL "")
