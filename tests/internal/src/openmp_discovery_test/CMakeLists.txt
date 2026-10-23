# Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
#
# SPDX-License-Identifier: (BSD-3-Clause)

cmake_minimum_required(VERSION 3.15)
project(blt_openmp_discovery_test LANGUAGES C CXX)

set(_test_languages C CXX)
if(ENABLE_FORTRAN)
    enable_language(Fortran)
    list(APPEND _test_languages Fortran)
endif()

set(_existing_languages)
if(DISCOVERY_CASE STREQUAL "existing")
    set(_existing_languages ${_test_languages})
elseif(DISCOVERY_CASE STREQUAL "partial")
    set(_existing_languages CXX)
elseif(NOT DISCOVERY_CASE STREQUAL "initial")
    message(FATAL_ERROR "Unknown OpenMP discovery case: ${DISCOVERY_CASE}")
endif()

if(_existing_languages)
    find_package(OpenMP REQUIRED COMPONENTS ${_existing_languages})
    foreach(_lang IN LISTS _existing_languages)
        target_compile_options(OpenMP::OpenMP_${_lang} INTERFACE
                               "$<$<COMPILE_LANGUAGE:${_lang}>:-DBLT_OPENMP_CONSUMER_OPTION>")
        get_target_property(_expected_${_lang} OpenMP::OpenMP_${_lang}
                            INTERFACE_COMPILE_OPTIONS)
    endforeach()
endif()

# Exercise the path used by an installed BLT dependency.
set(ENABLE_OPENMP ON)
include("${BLT_SOURCE_DIR}/cmake/BLTSetupTargets.cmake")

foreach(_lang IN LISTS _test_languages)
    if(NOT TARGET OpenMP::OpenMP_${_lang})
        message(FATAL_ERROR "OpenMP::OpenMP_${_lang} was not discovered")
    endif()
    if(NOT DEFINED OpenMP_${_lang}_FLAGS)
        message(FATAL_ERROR "OpenMP_${_lang}_FLAGS is missing")
    endif()
endforeach()

foreach(_lang IN LISTS _existing_languages)
    get_target_property(_actual OpenMP::OpenMP_${_lang}
                        INTERFACE_COMPILE_OPTIONS)
    if(NOT "${_actual}" STREQUAL "${_expected_${_lang}}")
        message(FATAL_ERROR "OpenMP::OpenMP_${_lang} consumer options changed:"
                            " '${_expected_${_lang}}' -> '${_actual}'")
    endif()
endforeach()

if(NOT TARGET blt::openmp)
    message(FATAL_ERROR "BLT OpenMP target was not created")
endif()
