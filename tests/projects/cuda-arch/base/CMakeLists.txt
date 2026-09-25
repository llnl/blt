cmake_minimum_required(VERSION 3.14)

project(cuda-clang-cpp LANGUAGES CXX)

# This test will verify that CUDA compile flags that are configurable by the user
# (these are the only two, besides the dir for the CUDA toolkit) will correctly be
# passed down to downstream projects.

# Load BLT
include(${BLT_SOURCE_DIR}/SetupBLT.cmake)

# Add third-party library setup files to the project's installation
# directory.
blt_install_tpl_setups(DESTINATION lib/cmake/${PROJECT_NAME})

# Add the base library with its single source file and header file.
blt_add_library(
  NAME cuda-clang-cpp
  SOURCES cuda-clang-cpp.cu
  HEADERS cuda-clang-cpp.cuh
  DEPENDS_ON blt::cuda)

# Add the header file to the installation.
install(FILES cuda-clang-cpp.cuh DESTINATION include)

# Install the header along with the necessary cmake files.
install(TARGETS cuda-clang-cpp
  EXPORT cuda-clang-cpp-targets)

# Install the *-config.cmake file, which will include `BLTSetupTargets` 
# when a downstream project calls `find_package` on this library.
install(FILES
  ${PROJECT_SOURCE_DIR}/cuda-clang-cpp-config.cmake
  DESTINATION lib/cmake/cuda-clang-cpp)

install(EXPORT cuda-clang-cpp-targets
    DESTINATION  lib/cmake/cuda-clang-cpp)
