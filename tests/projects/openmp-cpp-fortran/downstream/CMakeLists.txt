# Clear variables set in the host-config so we can test that they are inherited
# from the upstream project
foreach(_option MPI CUDA HIP OPENMP)
    unset(ENABLE_${_option} CACHE)
    unset(ENABLE_${_option})
endforeach()

cmake_minimum_required(VERSION 3.14)

project(openmp-cpp-fortran-user LANGUAGES CXX Fortran)

# Calling find_package sets up the TPL targets needed by the project
# in its argument.
find_package(openmp-cpp-fortran REQUIRED 
             NO_DEFAULT_PATH
             PATHS ${base_install_dir}/lib/cmake/openmp-cpp-fortran)

add_executable(openmp-cpp-fortran-user openmp-cpp-fortran-user.F)

target_link_libraries(openmp-cpp-fortran-user PUBLIC openmp-cpp-fortran)

set_source_files_properties(
    openmp-cpp-fortran-user.F
    PROPERTIES
    Fortran_FORMAT FREE)

get_target_property(imported_omp_flags openmp INTERFACE_COMPILE_OPTIONS)

set(expected_omp_flags $<$<NOT:$<COMPILE_LANGUAGE:Fortran>>:SHELL:-fopenmp=libomp>;$<$<COMPILE_LANGUAGE:Fortran>:SHELL:-fopenmp>)

# The below print statement should emit the generator expression for the OMP flags,
# which is necessary because the flag is CPP and Fortran compiler dependent.
if (NOT "${imported_omp_flags}" STREQUAL "${expected_omp_flags}")
    message(FATAL_ERROR "Expected generator expression ${expected_omp_flags} but got ${imported_omp_flags}.\n"
                        "If the compile flag generator expression inside BLTSetupOpenMP.cmake was changed, please"
                        "update this test.  Otherwise, this test has failed.")
endif()
