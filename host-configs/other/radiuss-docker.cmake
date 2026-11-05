# Copyright (c) Lawrence Livermore National Security, LLC and other
# BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)

#------------------------------------------------------------------------------
# Example host-config file for the a basic AWS EC2 instance with OpenMPI
#------------------------------------------------------------------------------
#
# This file provides CMake with paths / details for:
#  C, C++, & Fortran compilers + MPI
# 
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# gcc@11 compilers (Ubuntu 22.04 RADIUSS base image)
#------------------------------------------------------------------------------

set(CMAKE_C_COMPILER "/usr/bin/gcc" CACHE PATH "")
set(CMAKE_CXX_COMPILER "/usr/bin/g++" CACHE PATH "")

set(ENABLE_FORTRAN ON CACHE BOOL "")
set(CMAKE_Fortran_COMPILER "/usr/bin/gfortran" CACHE PATH "")

#------------------------------------------------------------------------------
# MPI Support
#------------------------------------------------------------------------------
set(ENABLE_MPI ON CACHE BOOL "")

# OpenMPI installed via apt (openmpi-bin + libopenmpi-dev) puts the compiler
# wrappers and mpirun in /usr/bin.
set(MPI_C_COMPILER       "/usr/bin/mpicc" CACHE PATH "")
set(MPI_CXX_COMPILER     "/usr/bin/mpicxx" CACHE PATH "")
set(MPI_Fortran_COMPILER "/usr/bin/mpif90" CACHE PATH "")

set(MPIEXEC              "/usr/bin/mpirun" CACHE PATH "")
set(MPIEXEC_NUMPROC_FLAG "-np" CACHE STRING "")
set(BLT_MPI_COMMAND_APPEND "--oversubscribe" CACHE STRING "")
