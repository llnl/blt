# Copyright (c) Lawrence Livermore National Security, LLC and
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
# Avoid touching the source timestamp on each incremental reconfigure.
if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/empty.cpp")
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/empty.cpp" "void patch_target_test() {}\n")
endif()
add_library(patch_regular STATIC "${CMAKE_CURRENT_BINARY_DIR}/empty.cpp")
add_library(patch_interface INTERFACE)

set(patch_targets patch_regular patch_interface)
foreach(type STATIC SHARED UNKNOWN INTERFACE)
    add_library(patch_imported_${type} ${type} IMPORTED)
    list(APPEND patch_targets patch_imported_${type})
endforeach()

set(_patch_target_link_args LINK_FLAGS "SHELL:patch_target_link_flag")

foreach(target ${patch_targets})
    blt_patch_target(NAME ${target} LIBRARIES patch_library)
    blt_patch_target(NAME ${target} DEPENDS_ON patch_dependency)
    check_patch_target_property(${target} LINK_LIBRARIES "patch_library;patch_dependency")

    blt_patch_target(NAME ${target} INCLUDES "${CMAKE_CURRENT_SOURCE_DIR}")
    check_patch_target_property(${target} INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}")

    blt_patch_target(NAME ${target} FORTRAN_MODULES "${CMAKE_CURRENT_BINARY_DIR}")
    check_patch_target_property(${target} INCLUDE_DIRECTORIES
                                "${CMAKE_CURRENT_SOURCE_DIR};${CMAKE_CURRENT_BINARY_DIR}")

    blt_patch_target(NAME ${target}
                     COMPILE_FLAGS -DBLT_PATCH_TARGET_COMPILE_FLAG
                     ${_patch_target_link_args}
                     DEFINES BLT_PATCH_TARGET_TEST)
    check_patch_target_property(${target} COMPILE_DEFINITIONS BLT_PATCH_TARGET_TEST)
    check_patch_target_property(${target} COMPILE_OPTIONS -DBLT_PATCH_TARGET_COMPILE_FLAG)

    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.13")
        # This flag is checked as a property only; none of these targets link.
        check_patch_target_property(${target} LINK_OPTIONS "SHELL:patch_target_link_flag")
    endif()
endforeach()

# Direct target helpers default to PUBLIC. Imported non-interface targets must
# receive INTERFACE usage requirements instead.
foreach(target patch_imported_STATIC patch_imported_SHARED patch_imported_UNKNOWN)
    blt_determine_scope(TARGET ${target} OUT scope)
    if(NOT "${scope}" STREQUAL "INTERFACE")
        message(FATAL_ERROR "${target}: expected INTERFACE scope, got '${scope}'")
    endif()

    blt_add_target_definitions(TO ${target} TARGET_DEFINITIONS BLT_IMPORTED_DEFAULT_SCOPE)
    check_patch_target_property(${target} COMPILE_DEFINITIONS
                                "BLT_PATCH_TARGET_TEST;BLT_IMPORTED_DEFAULT_SCOPE")

    blt_add_target_compile_flags(TO ${target} FLAGS -DBLT_IMPORTED_DEFAULT_SCOPE)
    check_patch_target_property(${target} COMPILE_OPTIONS
                                "-DBLT_PATCH_TARGET_COMPILE_FLAG;-DBLT_IMPORTED_DEFAULT_SCOPE")

    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.13")
        blt_add_target_link_flags(TO ${target} FLAGS "SHELL:imported_default_scope_flag")
        check_patch_target_property(${target} LINK_OPTIONS
                                    "SHELL:patch_target_link_flag;SHELL:imported_default_scope_flag")
    endif()
endforeach()
