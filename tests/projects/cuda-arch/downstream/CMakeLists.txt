# Clear variables set in the host-config so we can test that they are inherited
# from the upstream project
foreach(_option MPI CUDA HIP OPENMP)
    unset(ENABLE_${_option} CACHE)
    unset(ENABLE_${_option})
endforeach()

cmake_minimum_required(VERSION 3.14)

project(cuda-clang-cpp-user LANGUAGES CXX)

# Load BLT
include(${BLT_SOURCE_DIR}/SetupBLT.cmake)

# Calling find_package sets up the TPL targets needed by the project
# in its argument.
find_package(cuda-clang-cpp REQUIRED
  NO_DEFAULT_PATH
  PATHS ${base_install_dir}/lib/cmake/cuda-clang-cpp
  ${base_install_dir})

if (NOT TARGET blt::cuda)
  message(FATAL_ERROR "Target cuda was not configured successfully during"
                      "downstream project configuration.")
endif()

# Compile a basic example to test correctness of link and compile flags.
blt_add_executable(
  NAME hello-cuda
  SOURCES cuda-clang-cpp-user.cpp
  DEPENDS_ON cuda-clang-cpp blt::cuda
)

target_include_directories(hello-cuda PUBLIC ${base_install_dir}/include)
