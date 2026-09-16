# Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
#
# SPDX-License-Identifier: (BSD-3-Clause)

################################
# Sanity Checks
################################

if( ${CMAKE_VERSION} VERSION_LESS "3.17.0" )
  message(FATAL_ERROR "CUDA support requires CMake >= 3.17.0")
endif ()

# CMAKE_CUDA_HOST_COMPILER needs to be set prior to enabling the CUDA language
get_property(_languages GLOBAL PROPERTY ENABLED_LANGUAGES)

if ( NOT CMAKE_CUDA_HOST_COMPILER )
    if("CUDA" IN_LIST _languages )
        message( FATAL_ERROR
                 "CUDA language enabled prior to setting CMAKE_CUDA_HOST_COMPILER. "
                 "Please set CMAKE_CUDA_HOST_COMPILER prior to "
                 "ENABLE_LANGUAGE(CUDA) or PROJECT(.. LANGUAGES CUDA)")
    endif()

    if ( CMAKE_CXX_COMPILER )
        set(CMAKE_CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER} CACHE STRING "" FORCE)
    else()
        set(CMAKE_CUDA_HOST_COMPILER ${CMAKE_C_COMPILER} CACHE STRING "" FORCE)
    endif()
endif()

if(CUDA_TOOLKIT_ROOT_DIR AND NOT CUDAToolkit_ROOT)
    set(CUDAToolkit_ROOT "${CUDA_TOOLKIT_ROOT_DIR}" CACHE PATH
        "Root directory of the CUDA Toolkit" FORCE)
endif()

if(DEFINED CUDA_SEPARABLE_COMPILATION AND NOT DEFINED CMAKE_CUDA_SEPARABLE_COMPILATION)
    set(CMAKE_CUDA_SEPARABLE_COMPILATION "${CUDA_SEPARABLE_COMPILATION}" CACHE BOOL
        "Build CUDA objects with separable compilation enabled" FORCE)
endif()


############################################################
# Basics
############################################################
enable_language(CUDA)

############################################################
# Find CUDA
############################################################
find_package(CUDAToolkit REQUIRED)
blt_assert_exists( TARGETS CUDA::cudart )

if(NOT CUDAToolkit_ROOT AND CUDAToolkit_BIN_DIR)
    get_filename_component(CUDAToolkit_ROOT "${CUDAToolkit_BIN_DIR}" DIRECTORY)
endif()

# Provide compatibility variables for projects that still query the old names.
set(CUDA_FOUND ${CUDAToolkit_FOUND})
set(CUDA_VERSION_STRING ${CUDAToolkit_VERSION})
set(CUDA_INCLUDE_DIRS ${CUDAToolkit_INCLUDE_DIRS})
set(CUDA_LIBRARIES CUDA::cudart)

############################################################
# Output information about CUDA
############################################################
message(STATUS "CUDA Version:                   ${CUDAToolkit_VERSION}")
message(STATUS "CUDA Toolkit Root Dir:          ${CUDAToolkit_ROOT}")
message(STATUS "CUDA Compiler:                  ${CMAKE_CUDA_COMPILER}")
message(STATUS "CUDA Host Compiler:             ${CMAKE_CUDA_HOST_COMPILER}")
message(STATUS "CUDA Standard:                  ${CMAKE_CUDA_STANDARD}")
if( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.18" )
message(STATUS "CUDA Architectures:             ${CMAKE_CUDA_ARCHITECTURES}")
endif()
message(STATUS "CUDA Include Path:              ${CUDAToolkit_INCLUDE_DIRS}")
message(STATUS "CUDA Runtime Target:            CUDA::cudart")
message(STATUS "CUDA Compile Flags:             ${CMAKE_CUDA_FLAGS}")
message(STATUS "CUDA Link Flags:                ${CMAKE_CUDA_LINK_FLAGS}")
message(STATUS "CUDA Separable Compilation:     ${CMAKE_CUDA_SEPARABLE_COMPILATION}")
message(STATUS "CUDA Implicit Link Libraries:   ${CMAKE_CUDA_IMPLICIT_LINK_LIBRARIES}")
message(STATUS "CUDA Implicit Link Directories: ${CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES}")

############################################################
# Check CUDA language standard is supported
############################################################
if(CMAKE_CUDA_STANDARD STREQUAL "17")
    if(NOT DEFINED CMAKE_CUDA_COMPILE_FEATURES OR (NOT "cuda_std_17" IN_LIST CMAKE_CUDA_COMPILE_FEATURES))
        message(FATAL_ERROR "CUDA ${CUDAToolkit_VERSION} does not support C++17.")
    endif()
endif()

if(CMAKE_CUDA_STANDARD STREQUAL "20")
    if(NOT DEFINED CMAKE_CUDA_COMPILE_FEATURES OR (NOT "cuda_std_20" IN_LIST CMAKE_CUDA_COMPILE_FEATURES))
        message(FATAL_ERROR "CUDA ${CUDAToolkit_VERSION} does not support C++20.")
    endif()
endif()

# Set PIE options to empty for PGI since it doesn't understand -fPIE This
# option is set in the CUDA toolchain file so must be unset after
# enable_language(CUDA)
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "PGI")
  set(CMAKE_CUDA_COMPILE_OPTIONS_PIE "")
endif()


# CUDA targets must be global for aliases when created as imported targets.
set(_blt_cuda_is_global On)
if(${BLT_EXPORT_THIRDPARTY})
    set(_blt_cuda_is_global Off)
endif()

# Use DEPENDS_ON to keep the CUDA::cudart imported library target in the link
# interface. blt_inherit_target_info() only copies interface usage properties.

# Use the CUDA runtime without flagging source files as
# CUDA language.  This causes your source files to use
# the regular C/CXX compiler. This is separate from
# linking with nvcc.
# This logic is handled in the blt_add_library/executable
# macros
blt_import_library(NAME          cuda_runtime
                   INCLUDES      ${CUDAToolkit_INCLUDE_DIRS}
                   TREAT_INCLUDES_AS_SYSTEM ON
                   DEPENDS_ON    CUDA::cudart
                   EXPORTABLE    ${BLT_EXPORT_THIRDPARTY}
                   GLOBAL        ${_blt_cuda_is_global})

add_library(blt::cuda_runtime ALIAS cuda_runtime)

# depend on 'cuda', if you need to use cuda
# headers, link to cuda libs, and need to compile your
# source files with the cuda compiler (nvcc) instead of
# leaving it to the default source file language.
# This logic is handled in the blt_add_library/executable
# macros
blt_import_library(NAME          cuda
                   DEPENDS_ON    cuda_runtime
                   EXPORTABLE    ${BLT_EXPORT_THIRDPARTY}
                   GLOBAL        ${_blt_cuda_is_global})

add_library(blt::cuda ALIAS cuda)
