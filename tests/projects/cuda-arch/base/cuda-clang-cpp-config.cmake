# This file exists so that when a downstream library calls `find_package`,
# the installed TPL setup files will be included.

include("${CMAKE_CURRENT_LIST_DIR}/cuda-clang-cpp-targets.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/BLTSetupTargets.cmake")
