# Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)

#------------------------------------------------------------------------------
# Example host-config file for the Summit cluster at the OLCF
#------------------------------------------------------------------------------
# This file provides CMake with paths / details for:
#  C,C++, & Fortran compilers + MPI & CUDA
#
# As of 3/29/2021 - these settings match summit modules:
#  gcc
#  cuda
#
# We recommend loading these modules.
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# gcc@9.4.3 compilers
#------------------------------------------------------------------------------
set(GCC_HOME "/sw/summit/gcc/6.4.0")
set(CMAKE_C_COMPILER   "${GCC_HOME}/bin/gcc" CACHE PATH "")
set(CMAKE_CXX_COMPILER "${GCC_HOME}/bin/g++" CACHE PATH "")

# Fortran support
set(ENABLE_FORTRAN ON CACHE BOOL "")
set(CMAKE_Fortran_COMPILER "${GCC_HOME}/bin/gfortran" CACHE PATH "")

#------------------------------------------------------------------------------
# MPI Support
#------------------------------------------------------------------------------
set(ENABLE_MPI ON CACHE BOOL "")

set(MPI_HOME "/autofs/nccs-svm1_sw/summit/.swci/1-compute/opt/spack/20180914/linux-rhel7-ppc64le/gcc-6.4.0/spectrum-mpi-10.3.1.2-20200121-awz2q5brde7wgdqqw4ugalrkukeub4eb")
set(MPI_C_COMPILER "${MPI_HOME}/bin/mpicc" CACHE PATH "")

set(MPI_CXX_COMPILER "${MPI_HOME}/bin/mpicxx" CACHE PATH "")

set(MPI_Fortran_COMPILER "${MPI_HOME}/bin/mpif90" CACHE PATH "")

set(MPIEXEC_EXECUTABLE "/sw/summit/xalt/1.2.1/bin/jsrun" CACHE PATH "")

#------------------------------------------------------------------------------
# CUDA support
#------------------------------------------------------------------------------
set(ENABLE_CUDA ON CACHE BOOL "")

set(CUDAToolkit_ROOT "/sw/summit/cuda/10.1.243/" CACHE PATH "")
set(CMAKE_CUDA_COMPILER "${CUDAToolkit_ROOT}/bin/nvcc" CACHE PATH "")
set(CMAKE_CUDA_HOST_COMPILER "${CMAKE_CXX_COMPILER}" CACHE PATH "")

set(CMAKE_CUDA_ARCHITECTURES "70" CACHE STRING "")
set(CMAKE_CUDA_FLAGS "-restrict --expt-extended-lambda -G"
    CACHE STRING "")

set(CMAKE_CUDA_SEPARABLE_COMPILATION ON CACHE BOOL "")
