#------------------------------------------------------------------------------
# !!!! This is a generated file, edit at own risk !!!!
#------------------------------------------------------------------------------
# CMake executable path: /usr/tce/packages/cmake/cmake-3.21.1/bin/cmake
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Compilers
#------------------------------------------------------------------------------
# Compiler Spec: gcc@10.3.1
#------------------------------------------------------------------------------

set(GCC_VERSION "gcc-10.3.1")
set(GCC_HOME "/usr/tce/packages/gcc/${GCC_VERSION}")

set(CMAKE_C_COMPILER "${GCC_HOME}/bin/gcc" CACHE PATH "")
set(CMAKE_CXX_COMPILER "${GCC_HOME}/bin/g++" CACHE PATH "")
set(CMAKE_Fortran_COMPILER "${GCC_HOME}/bin/gfortran" CACHE PATH "")

set(ENABLE_FORTRAN ON CACHE BOOL "")

#------------------------------------------------------------------------------
# MPI
#------------------------------------------------------------------------------

set(_mpi_root "/usr/tce/packages/cray-mpich-tce/cray-mpich-8.1.28-rocmcc-6.0.2")

set(MPI_C_COMPILER "${_mpi_root}/bin/mpicc" CACHE PATH "")

set(MPI_CXX_COMPILER "${_mpi_root}/bin/mpicxx" CACHE PATH "")

set(MPI_Fortran_COMPILER "${_mpi_root}/bin/mpif90" CACHE PATH "")

set(MPIEXEC_EXECUTABLE "/usr/global/tools/flux_wrappers/bin/srun" CACHE PATH "")

set(MPIEXEC_NUMPROC_FLAG "-n" CACHE STRING "")

set(ENABLE_MPI ON CACHE BOOL "")

#------------------------------------------------------------------------------
# HIP
#------------------------------------------------------------------------------

set(_rocm_root "/opt/rocm-6.0.2")

set(ROCM_ROOT_DIR "${_rocm_root}" CACHE PATH "")

set(ENABLE_HIP ON CACHE BOOL "")

set(CMAKE_HIP_COMPILER "${_rocm_root}/bin/amdclang++" CACHE PATH "")

set(CMAKE_HIP_ARCHITECTURES "gfx942" CACHE STRING "")

#------------------------------------------------
# Hardware Specifics
#------------------------------------------------

set(ENABLE_OPENMP OFF CACHE BOOL "")

set(ENABLE_GTEST_DEATH_TESTS ON CACHE BOOL "")
