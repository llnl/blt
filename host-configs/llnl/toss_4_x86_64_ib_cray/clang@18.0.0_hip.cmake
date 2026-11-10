#------------------------------------------------------------------------------
# !!!! This is a generated file, edit at own risk !!!!
#------------------------------------------------------------------------------
# CMake executable path: /usr/tce/packages/cmake/cmake-3.21.1/bin/cmake
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Compilers
#------------------------------------------------------------------------------
# Compiler Spec: clang@18.0.0
#------------------------------------------------------------------------------

#_blt_tutorial_hip_compiler_start
set(_compiler_root "/opt/rocm-6.2.1/llvm")

set(CMAKE_C_COMPILER "${_compiler_root}/bin/amdclang" CACHE PATH "")

set(CMAKE_CXX_COMPILER "${_compiler_root}/bin/amdclang++" CACHE PATH "")

set(CMAKE_Fortran_COMPILER "${_compiler_root}/bin/amdflang" CACHE PATH "")

set(CMAKE_Fortran_FLAGS "-Mfreeform" CACHE STRING "")

set(ENABLE_FORTRAN ON CACHE BOOL "")
#_blt_tutorial_hip_compiler_end

#------------------------------------------------------------------------------
# MPI
#------------------------------------------------------------------------------

set(_mpi_root "/usr/tce/packages/cray-mpich-tce/cray-mpich-8.1.31-rocmcc-6.2.1")

set(MPI_C_COMPILER "${_mpi_root}/bin/mpicc" CACHE PATH "")

set(MPI_CXX_COMPILER "${_mpi_root}/bin/mpicxx" CACHE PATH "")

set(MPI_Fortran_COMPILER "${_mpi_root}/bin/mpif90" CACHE PATH "")

set(MPIEXEC_EXECUTABLE "/usr/global/tools/flux_wrappers/bin/srun" CACHE PATH "")

set(MPIEXEC_NUMPROC_FLAG "-n" CACHE STRING "")

set(ENABLE_MPI ON CACHE BOOL "")

#------------------------------------------------------------------------------
# Hardware
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

# HIP

#------------------------------------------------------------------------------

#_blt_tutorial_useful_hip_variables_start
set(ROCM_ROOT_DIR "/opt/rocm-6.2.1" CACHE PATH "")

set(ENABLE_HIP ON CACHE BOOL "")

set(CMAKE_HIP_ARCHITECTURES "gfx942" CACHE STRING "")

set(CMAKE_EXE_LINKER_FLAGS "-Wl,--disable-new-dtags -L${ROCM_ROOT_DIR}/llvm/lib -L${ROCM_ROOT_DIR}/lib -Wl,-rpath,${ROCM_ROOT_DIR}/llvm/lib:${ROCM_ROOT_DIR}/lib -lpgmath -lflang -lflangrti -lompstub -lamdhip64  -L${ROCM_ROOT_DIR}/lib64 -Wl,-rpath,${ROCM_ROOT_DIR}/lib64  -L${ROCM_ROOT_DIR}/lib -Wl,-rpath,${ROCM_ROOT_DIR}/lib -lamd_comgr -lhsa-runtime64 " CACHE STRING "")

#_blt_tutorial_useful_hip_variables_end

#------------------------------------------------
# Hardware Specifics
#------------------------------------------------

set(ENABLE_OPENMP OFF CACHE BOOL "")

set(ENABLE_GTEST_DEATH_TESTS ON CACHE BOOL "")
