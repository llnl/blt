# Copyright (c) Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
#
# SPDX-License-Identifier: (BSD-3-Clause)

# A CTest re-run must not reuse cached OpenMP discovery from an earlier run.
# Run each case in its own freshly-created directory.
if(NOT DEFINED TEST_BINARY_DIR OR NOT DEFINED TEST_SOURCE_DIR)
    message(FATAL_ERROR "OpenMP regression test source/build directories are required")
endif()
file(REMOVE_RECURSE "${TEST_BINARY_DIR}")

set(_cmake_args
    -S "${TEST_SOURCE_DIR}"
    -B "${TEST_BINARY_DIR}"
    -G "${TEST_GENERATOR}"
    "-DBLT_SOURCE_DIR=${BLT_SOURCE_DIR}"
    "-DDISCOVERY_CASE=${DISCOVERY_CASE}"
    "-DENABLE_FORTRAN=${ENABLE_FORTRAN}"
    "-DCMAKE_C_COMPILER=${TEST_C_COMPILER}"
    "-DCMAKE_CXX_COMPILER=${TEST_CXX_COMPILER}")

if(TEST_Fortran_COMPILER)
    list(APPEND _cmake_args "-DCMAKE_Fortran_COMPILER=${TEST_Fortran_COMPILER}")
endif()
if(TEST_GENERATOR_PLATFORM)
    list(APPEND _cmake_args -A "${TEST_GENERATOR_PLATFORM}")
endif()
if(TEST_GENERATOR_TOOLSET)
    list(APPEND _cmake_args -T "${TEST_GENERATOR_TOOLSET}")
endif()
if(TEST_MAKE_PROGRAM)
    list(APPEND _cmake_args "-DCMAKE_MAKE_PROGRAM=${TEST_MAKE_PROGRAM}")
endif()

execute_process(COMMAND "${CMAKE_COMMAND}" ${_cmake_args}
                RESULT_VARIABLE _result)
if(NOT _result EQUAL 0)
    message(FATAL_ERROR "OpenMP discovery regression ${DISCOVERY_CASE} failed")
endif()
