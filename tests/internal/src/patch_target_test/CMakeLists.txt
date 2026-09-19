# Copyright (c) 2017-2026, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
#
# SPDX-License-Identifier: (BSD-3-Clause)

# Check usage requirements and ensure ordinary libraries retain PUBLIC scope.
function(check_patch_target_property target property expected)
    get_target_property(actual ${target} INTERFACE_${property})
    if(NOT "${actual}" STREQUAL "${expected}")
        message(FATAL_ERROR "${target}: unexpected INTERFACE_${property}: '${actual}'")
    endif()

    get_target_property(imported ${target} IMPORTED)
    get_target_property(type ${target} TYPE)
    if(NOT imported AND NOT type STREQUAL "INTERFACE_LIBRARY")
        get_target_property(actual ${target} ${property})
        if(NOT "${actual}" STREQUAL "${expected}")
            message(FATAL_ERROR "${target}: unexpected ${property}: '${actual}'")
        endif()
    endif()
endfunction()

add_library(patch_dependency INTERFACE)
add_library(patch_library INTERFACE)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/empty.cpp" "void patch_target_test() {}\n")
add_library(patch_regular STATIC "${CMAKE_CURRENT_BINARY_DIR}/empty.cpp")
add_library(patch_interface INTERFACE)

set(patch_targets patch_regular patch_interface)
foreach(type STATIC SHARED UNKNOWN INTERFACE)
    add_library(patch_imported_${type} ${type} IMPORTED)
    list(APPEND patch_targets patch_imported_${type})
endforeach()

foreach(target ${patch_targets})
    blt_patch_target(NAME ${target} LIBRARIES patch_library)
    blt_patch_target(NAME ${target} DEPENDS_ON patch_dependency)
    check_patch_target_property(${target} LINK_LIBRARIES "patch_library;patch_dependency")

    blt_patch_target(NAME ${target} INCLUDES "${CMAKE_CURRENT_SOURCE_DIR}")
    check_patch_target_property(${target} INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}")

    blt_patch_target(NAME ${target} FORTRAN_MODULES "${CMAKE_CURRENT_BINARY_DIR}")
    check_patch_target_property(${target} INCLUDE_DIRECTORIES
                                "${CMAKE_CURRENT_SOURCE_DIR};${CMAKE_CURRENT_BINARY_DIR}")

    blt_patch_target(NAME ${target} DEFINES BLT_PATCH_TARGET_TEST)
    check_patch_target_property(${target} COMPILE_DEFINITIONS BLT_PATCH_TARGET_TEST)

    blt_patch_target(NAME ${target} COMPILE_FLAGS -DBLT_PATCH_TARGET_COMPILE_FLAG)
    check_patch_target_property(${target} COMPILE_OPTIONS -DBLT_PATCH_TARGET_COMPILE_FLAG)

    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.13")
        # This flag is checked as a property only; none of these targets link.
        blt_patch_target(NAME ${target} LINK_FLAGS "SHELL:patch_target_link_flag")
        check_patch_target_property(${target} LINK_OPTIONS "SHELL:patch_target_link_flag")
    endif()
endforeach()
