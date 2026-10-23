# Copyright (c) Lawrence Livermore National Security, LLC and other
# BLT Project Developers. See the top-level LICENSE file for details
#
# SPDX-License-Identifier: (BSD-3-Clause)

################################
# HIP
################################
 
if( ${CMAKE_VERSION} VERSION_LESS "3.21.0" )
  message(FATAL_ERROR "HIP support requires CMake >= 3.21.0")
endif ()

enable_language(HIP)

if(NOT ROCM_PATH)
    # First try finding paths given by the user
    find_path(ROCM_PATH
        hip
        PATHS
          $ENV{ROCM_DIR}
          $ENV{ROCM_PATH}
          $ENV{HIP_PATH}
          ${HIP_PATH}/..
          ${HIP_ROOT_DIR}/../
          ${ROCM_ROOT_DIR}
          /opt/rocm
        NO_DEFAULT_PATH
        NO_CMAKE_ENVIRONMENT_PATH
        NO_CMAKE_PATH
        NO_SYSTEM_ENVIRONMENT_PATH
        NO_CMAKE_SYSTEM_PATH)

    # If that fails, use CMake default paths
    if(NOT ROCM_PATH)
        find_path(ROCM_PATH hip)
    endif()
endif()

# Update CMAKE_PREFIX_PATH to make sure all the configs that hip depends on are
# found.
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${ROCM_PATH};${ROCM_ROOT_DIR}/lib/cmake")

find_package(hip REQUIRED CONFIG PATHS  ${HIP_PATH} ${ROCM_PATH} ${ROCM_ROOT_DIR}/lib/cmake/hip)

message(STATUS "ROCM path:        ${ROCM_PATH}")
message(STATUS "HIP version:      ${hip_VERSION}")

# AMDGPU_TARGETS should be defined in the hip-config.cmake that gets "included" via find_package(hip)
if(DEFINED AMDGPU_TARGETS)
    if(DEFINED CMAKE_HIP_ARCHITECTURES)
        set(AMDGPU_TARGETS "${CMAKE_HIP_ARCHITECTURES}" CACHE STRING "" FORCE)
    endif()
endif()

# hip targets must be global for aliases when created as imported targets
set(_blt_hip_is_global On)
if(${BLT_EXPORT_THIRDPARTY})
    set(_blt_hip_is_global Off)
endif()

# Guard against `--rocm-path` being added to crayftn less than version 15.0.0 due to
# invalid command line option error
if(CMAKE_Fortran_COMPILER_ID STREQUAL "Cray" AND CMAKE_Fortran_COMPILER_VERSION VERSION_LESS 15.0.0)
    set(_blt_hip_compile_flags "$<$<COMPILE_LANGUAGE:CXX>:SHELL:--rocm-path=${ROCM_PATH}>")
else()
    set(_blt_hip_compile_flags "--rocm-path=${ROCM_PATH}")
endif()

blt_import_library(NAME          blt_hip
                   EXPORTABLE    ${BLT_EXPORT_THIRDPARTY}
                   DEPENDS_ON    blt_hip_runtime
                   GLOBAL        ${_blt_hip_is_global})

add_library(blt::hip ALIAS blt_hip)


blt_import_library(NAME          blt_hip_runtime
                   INCLUDES      ${HIP_INCLUDE_DIRS}
                   TREAT_INCLUDES_AS_SYSTEM ON
                   EXPORTABLE    ${BLT_EXPORT_THIRDPARTY}
                   GLOBAL        ${_blt_hip_is_global})

blt_inherit_target_info(TO blt_hip_runtime FROM hip::host OBJECT FALSE)

add_library(blt::hip_runtime ALIAS blt_hip_runtime)
