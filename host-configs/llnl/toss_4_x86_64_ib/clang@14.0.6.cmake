# Copyright (c) Lawrence Livermore National Security, LLC and other
# BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)

#------------------------------------------------------------------------------
# Example host-config file for a cluster on a toss4 platform (e.g. dane) at LLNL
#------------------------------------------------------------------------------
#
# This file provides CMake with paths / details for:
#  C,C++, & Fortran compilers + MPI + OpenMP
#------------------------------------------------------------------------------
# clang-14.0.6 compilers

set(CLANG_VERSION "clang-14.0.6")
set(CLANG_HOME "/usr/tce/packages/clang/${CLANG_VERSION}")

# c compiler
set(CMAKE_C_COMPILER "${CLANG_HOME}/bin/clang" CACHE PATH "")

# cpp compiler
set(CMAKE_CXX_COMPILER "${CLANG_HOME}/bin/clang++" CACHE PATH "")

# fortran support
set(ENABLE_FORTRAN ON CACHE BOOL "")

# fortran compiler
set(CMAKE_Fortran_COMPILER "${GNU_HOME}/bin/gfortran" CACHE PATH "")

set(ENABLE_OPENMP ON CACHE BOOL "")

#------------------------------------------------------------------------------
# Static Analysis Support
#------------------------------------------------------------------------------
set(ClangQuery_DIR ${CLANG_HOME}/bin)
set(ENABLE_CLANGQUERY ON CACHE BOOL "")

set(ClangTidy_DIR ${CLANG_HOME}/bin)
set(ENABLE_CLANGTIDY ON CACHE BOOL "")

#------------------------------------------------------------------------------
# MPI Support
#------------------------------------------------------------------------------
set(ENABLE_MPI ON CACHE BOOL "")

set(MPI_HOME             "/usr/tce/packages/mvapich2/mvapich2-2.3.6-${CLANG_VERSION}" CACHE PATH "")
set(MPI_C_COMPILER       "${MPI_HOME}/bin/mpicc"   CACHE PATH "")
set(MPI_CXX_COMPILER     "${MPI_HOME}/bin/mpicxx"  CACHE PATH "")
set(MPI_Fortran_COMPILER "${MPI_HOME}/bin/mpifort" CACHE PATH "")

set(MPIEXEC              "/usr/bin/srun" CACHE PATH "")
set(MPIEXEC_NUMPROC_FLAG "-n" CACHE PATH "")
