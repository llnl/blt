# Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)

include(${BLT_ROOT_DIR}/cmake/BLTPrivateMacros.cmake)

##------------------------------------------------------------------------------
## blt_set_target_folder(TARGET <target> FOLDER <folder>)
##
## Sets the folder property of cmake target <target> to <folder>.
##------------------------------------------------------------------------------
macro(blt_set_target_folder)

    set(options)
    set(singleValuedArgs TARGET FOLDER)
    set(multiValuedArgs)

    # Parse the arguments to the macro
    cmake_parse_arguments(arg
         "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN} )

    # Sanity checks
    if(NOT DEFINED arg_TARGET)
        message(FATAL_ERROR "TARGET is a required parameter for blt_set_target_folder macro")
    endif()

    if(NOT TARGET ${arg_TARGET})
        message(FATAL_ERROR "Target ${arg_TARGET} passed to blt_set_target_folder is not a valid cmake target")
    endif()

    if(NOT DEFINED arg_FOLDER)
        message(FATAL_ERROR "FOLDER is a required parameter for blt_set_target_folder macro")
    endif()

    # Set the folder property for this target
    if(ENABLE_FOLDERS AND NOT "${arg_FOLDER}" STREQUAL "")
        set_property(TARGET ${arg_TARGET} PROPERTY FOLDER "${arg_FOLDER}")
    endif()

endmacro(blt_set_target_folder)


##------------------------------------------------------------------------------
## blt_register_library( NAME <libname>
##                       DEPENDS_ON [dep1 [dep2 ...]]
##                       INCLUDES [include1 [include2 ...]]
##                       TREAT_INCLUDES_AS_SYSTEM [ON|OFF]
##                       FORTRAN_MODULES [ path1 [ path2 ..]]
##                       LIBRARIES [lib1 [lib2 ...]]
##                       COMPILE_FLAGS [ flag1 [ flag2 ..]]
##                       LINK_FLAGS [ flag1 [ flag2 ..]]
##                       DEFINES [def1 [def2 ...]] )
##
## Registers a library to the project to ease use in other BLT macro calls.
##------------------------------------------------------------------------------
macro(blt_register_library)

    set(singleValueArgs NAME OBJECT TREAT_INCLUDES_AS_SYSTEM)
    set(multiValueArgs INCLUDES 
                       DEPENDS_ON
                       FORTRAN_MODULES
                       LIBRARIES
                       COMPILE_FLAGS
                       LINK_FLAGS
                       DEFINES )

    ## parse the arguments
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    string(TOUPPER ${arg_NAME} uppercase_name)

    set(_BLT_${uppercase_name}_IS_REGISTERED_LIBRARY TRUE CACHE BOOL "" FORCE)

    if( arg_DEPENDS_ON )
        set(_BLT_${uppercase_name}_DEPENDS_ON ${arg_DEPENDS_ON} CACHE STRING "" FORCE)
        mark_as_advanced(_BLT_${uppercase_name}_DEPENDS_ON)
    endif()

    if( arg_INCLUDES )
        set(_BLT_${uppercase_name}_INCLUDES ${arg_INCLUDES} CACHE STRING "" FORCE)
        mark_as_advanced(_BLT_${uppercase_name}_INCLUDES)
    endif()

    if( ${arg_OBJECT} )
        set(_BLT_${uppercase_name}_IS_OBJECT_LIBRARY TRUE CACHE BOOL "" FORCE)
    else()
        set(_BLT_${uppercase_name}_IS_OBJECT_LIBRARY FALSE CACHE BOOL "" FORCE)
    endif()
    mark_as_advanced(_BLT_${uppercase_name}_IS_OBJECT_LIBRARY)

    # PGI does not support -isystem
    if( (${arg_TREAT_INCLUDES_AS_SYSTEM}) AND (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "PGI"))
        set(_BLT_${uppercase_name}_TREAT_INCLUDES_AS_SYSTEM TRUE CACHE BOOL "" FORCE)
    else()
        set(_BLT_${uppercase_name}_TREAT_INCLUDES_AS_SYSTEM FALSE CACHE BOOL "" FORCE)
    endif()
    mark_as_advanced(_BLT_${uppercase_name}_TREAT_INCLUDES_AS_SYSTEM)

    if( ENABLE_FORTRAN AND arg_FORTRAN_MODULES )
        set(_BLT_${uppercase_name}_FORTRAN_MODULES ${arg_INCLUDES} CACHE STRING "" FORCE)
        mark_as_advanced(_BLT_${uppercase_name}_FORTRAN_MODULES)
    endif()

    if( arg_LIBRARIES )
        set(_BLT_${uppercase_name}_LIBRARIES ${arg_LIBRARIES} CACHE STRING "" FORCE)
    else()
        # This prevents cmake from falling back on adding -l<library name>
        # to the command line for BLT registered libraries which are not
        # actual CMake targets
        set(_BLT_${uppercase_name}_LIBRARIES "BLT_NO_LIBRARIES" CACHE STRING "" FORCE)
    endif()
    mark_as_advanced(_BLT_${uppercase_name}_LIBRARIES)

    if( arg_COMPILE_FLAGS )
        set(_BLT_${uppercase_name}_COMPILE_FLAGS "${arg_COMPILE_FLAGS}" CACHE STRING "" FORCE)
        mark_as_advanced(_BLT_${uppercase_name}_COMPILE_FLAGS)
    endif()

    if( arg_LINK_FLAGS )
        set(_BLT_${uppercase_name}_LINK_FLAGS "${arg_LINK_FLAGS}" CACHE STRING "" FORCE)
        mark_as_advanced(_BLT_${uppercase_name}_LINK_FLAGS)
    endif()

    if( arg_DEFINES )
        set(_BLT_${uppercase_name}_DEFINES ${arg_DEFINES} CACHE STRING "" FORCE)
        mark_as_advanced(_BLT_${uppercase_name}_DEFINES)
    endif()

endmacro(blt_register_library)

##------------------------------------------------------------------------------
## blt_add_library( NAME         <libname>
##                  SOURCES      [source1 [source2 ...]]
##                  HEADERS      [header1 [header2 ...]]
##                  INCLUDES     [dir1 [dir2 ...]]
##                  DEFINES      [define1 [define2 ...]]
##                  DEPENDS_ON   [dep1 ...] 
##                  OUTPUT_NAME  [name]
##                  OUTPUT_DIR   [dir]
##                  SHARED       [TRUE | FALSE]
##                  OBJECT       [TRUE | FALSE]
##                  CLEAR_PREFIX [TRUE | FALSE]
##                  FOLDER       [name])
##
## Adds a library target, called <libname>, to be built from the given sources.
##------------------------------------------------------------------------------
macro(blt_add_library)

    set(options)
    set(singleValueArgs NAME OUTPUT_NAME OUTPUT_DIR SHARED OBJECT CLEAR_PREFIX FOLDER)
    set(multiValueArgs SOURCES HEADERS INCLUDES DEFINES DEPENDS_ON)

    # parse the arguments
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    # Sanity checks
    if( "${arg_NAME}" STREQUAL "" )
        message(FATAL_ERROR "blt_add_library() must be called with argument NAME <name>")
    endif()

    if (NOT arg_SOURCES AND NOT arg_HEADERS )
        message(FATAL_ERROR "blt_add_library(NAME ${arg_NAME} ...) called with no given sources or headers")
    endif()

    if (DEFINED arg_OBJECT AND arg_OBJECT)
        if (DEFINED arg_SHARED AND arg_SHARED)
                message(FATAL_ERROR "blt_add_library(NAME ${arg_NAME} ...) cannot be called with both OBJECT and SHARED set to TRUE.")
        endif()

        if (NOT arg_SOURCES)
            message(FATAL_ERROR "blt_add_library(NAME ${arg_NAME} ...) cannot create an object library with no sources.")
        endif()
    endif()

    if ( arg_SOURCES )
        # Determine type of library to build. STATIC by default and OBJECT takes
        # precedence over global BUILD_SHARED_LIBS variable.
        set(_build_shared_library ${BUILD_SHARED_LIBS})
        if( DEFINED arg_SHARED )
            set(_build_shared_library ${arg_SHARED})
        endif()

        if ( ${arg_OBJECT} )
            set(_lib_type "OBJECT")
            blt_register_library( NAME       ${arg_NAME}
                                  DEPENDS_ON ${arg_DEPENDS_ON}
                                  INCLUDES   ${arg_INCLUDES}
                                  OBJECT     TRUE
                                  DEFINES    ${arg_DEFINES} )
        elseif ( ${_build_shared_library} )
            set(_lib_type "SHARED")
        else()
            set(_lib_type "STATIC")
        endif()

        add_library( ${arg_NAME} ${_lib_type} ${arg_SOURCES} ${arg_HEADERS} )

        if (BLT_ENABLE_CUDA)
            blt_setup_cuda_target(
                NAME         ${arg_NAME}
                SOURCES      ${arg_SOURCES}
                DEPENDS_ON   ${arg_DEPENDS_ON}
                LIBRARY_TYPE ${_lib_type})
        endif()

        if(BLT_ENABLE_HIP)
            blt_setup_hip_target(
                NAME         ${arg_NAME}
                SOURCES      ${arg_SOURCES}
                DEPENDS_ON   ${arg_DEPENDS_ON})
        endif()
    else()
        #
        #  Header-only library support
        #
        if( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.19.0" )
            # Adding headers here allows them to show up in IDE projects but is not
            # necessary for building
            add_library( ${arg_NAME} INTERFACE ${arg_HEADERS} )
        else()
            add_library( ${arg_NAME} INTERFACE )
        endif()
    endif()

    # Clear value of _have_fortran from previous calls
    set(_have_fortran False)

    # Must tell fortran where to look for modules
    # CMAKE_Fortran_MODULE_DIRECTORY is the location of generated modules
    foreach (_file ${arg_SOURCES})
        get_source_file_property(_lang ${_file} LANGUAGE)
        if(_lang STREQUAL Fortran)
            set(_have_fortran TRUE)
        endif()
    endforeach()
    if(_have_fortran)
        target_include_directories(${arg_NAME} PRIVATE ${CMAKE_Fortran_MODULE_DIRECTORY})
    endif()

    blt_setup_target( NAME       ${arg_NAME}
                      DEPENDS_ON ${arg_DEPENDS_ON} 
                      OBJECT     ${arg_OBJECT})

    if ( arg_INCLUDES )
        if (NOT arg_SOURCES )
            # Header only
            target_include_directories(${arg_NAME} INTERFACE ${arg_INCLUDES})
        else()
            target_include_directories(${arg_NAME} PUBLIC ${arg_INCLUDES})
        endif()
    endif()

    if ( arg_DEFINES )
        target_compile_definitions(${arg_NAME} PUBLIC ${arg_DEFINES})
    endif()

    if ( arg_OUTPUT_DIR )
        set_target_properties(${arg_NAME} PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY ${arg_OUTPUT_DIR} )
    endif()

    if ( arg_OUTPUT_NAME )
        set_target_properties(${arg_NAME} PROPERTIES
            OUTPUT_NAME ${arg_OUTPUT_NAME} )
    endif()

    if ( arg_CLEAR_PREFIX )
        set_target_properties(${arg_NAME} PROPERTIES
            PREFIX "" )
    endif()

    # Handle optional FOLDER keyword for this target
    if(ENABLE_FOLDERS AND DEFINED arg_FOLDER)
        blt_set_target_folder(TARGET ${arg_NAME} FOLDER "${arg_FOLDER}")
    endif()

    if ( arg_SOURCES )
        # Don't clean header-only libraries because you would have to handle
        # the white-list of properties that are allowed
        blt_clean_target(TARGET ${arg_NAME})
    endif()

endmacro(blt_add_library)


##------------------------------------------------------------------------------
## blt_add_executable( NAME        <name>
##                     SOURCES     [source1 [source2 ...]]
##                     HEADERS     [header1 [header2 ...]]
##                     INCLUDES    [dir1 [dir2 ...]]
##                     DEFINES     [define1 [define2 ...]]
##                     DEPENDS_ON  [dep1 [dep2 ...]]
##                     OUTPUT_DIR  [dir]
##                     OUTPUT_NAME [name]
##                     FOLDER      [name])
##
## Adds an executable target, called <name>, to be built from the given sources.
##------------------------------------------------------------------------------
macro(blt_add_executable)

    set(options )
    set(singleValueArgs NAME OUTPUT_DIR OUTPUT_NAME FOLDER)
    set(multiValueArgs HEADERS SOURCES INCLUDES DEFINES DEPENDS_ON)

    # Parse the arguments to the macro
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN})

    # Sanity checks
    if( "${arg_NAME}" STREQUAL "" )
        message(FATAL_ERROR "blt_add_executable() must be called with argument NAME <name>")
    endif()

    if (NOT arg_SOURCES )
        message(FATAL_ERROR "blt_add_executable(NAME ${arg_NAME} ...) given with no sources")
    endif()

    add_executable( ${arg_NAME} ${arg_SOURCES} ${arg_HEADERS})

    if (BLT_ENABLE_CUDA)
        blt_setup_cuda_target(
            NAME         ${arg_NAME}
            SOURCES      ${arg_SOURCES}
            DEPENDS_ON   ${arg_DEPENDS_ON})
    endif()
    
    if(BLT_ENABLE_HIP)
        blt_setup_hip_target(
            NAME         ${arg_NAME}
            SOURCES      ${arg_SOURCES}
            DEPENDS_ON   ${arg_DEPENDS_ON})
    endif()
    
    # CMake wants to load with C++ if any of the libraries are C++.
    # Force to load with Fortran if the first file is Fortran.
    list(GET arg_SOURCES 0 _first)
    get_source_file_property(_lang ${_first} LANGUAGE)
    if(_lang STREQUAL Fortran)
        set_target_properties( ${arg_NAME} PROPERTIES LINKER_LANGUAGE Fortran )
        target_include_directories(${arg_NAME} PRIVATE ${CMAKE_Fortran_MODULE_DIRECTORY})
    endif()
       
    blt_setup_target(NAME       ${arg_NAME}
                     DEPENDS_ON ${arg_DEPENDS_ON} 
                     OBJECT     FALSE)

    # Override the linker language with INTERFACE_BLT_LINKER_LANGUAGE_OVERRIDE, if applicable
    # Will have just been populated by blt_setup_target
    get_target_property(_blt_link_lang ${arg_NAME} INTERFACE_BLT_LINKER_LANGUAGE_OVERRIDE)
    if(_blt_link_lang)
        # This is the final link (b/c executable), so override the actual LINKER_LANGUAGE
        # BLT currently uses this to override for HIP and CUDA linkers
        set_target_properties(${arg_NAME} PROPERTIES LINKER_LANGUAGE ${_blt_link_lang})
    endif()

    if ( arg_INCLUDES )
        target_include_directories(${arg_NAME} PUBLIC ${arg_INCLUDES})
    endif()

    if ( arg_DEFINES )
        target_compile_definitions(${arg_NAME} PUBLIC ${arg_DEFINES})
    endif()

    if ( arg_OUTPUT_NAME )
        set_target_properties(${arg_NAME} PROPERTIES
            OUTPUT_NAME ${arg_OUTPUT_NAME} )
    endif()

    # when using shared libs on windows, all runtime targets
    # (dlls and exes) must live in the same dir
    # so we do not set runtime_output_dir in this case
    if ( arg_OUTPUT_DIR AND NOT (WIN32 AND BUILD_SHARED_LIBS) )
           set_target_properties(${arg_NAME} PROPERTIES
           RUNTIME_OUTPUT_DIRECTORY ${arg_OUTPUT_DIR} )
    endif()

    # Handle optional FOLDER keyword for this target
    if(ENABLE_FOLDERS AND DEFINED arg_FOLDER)
        blt_set_target_folder(TARGET ${arg_NAME} FOLDER "${arg_FOLDER}")
    endif()

    blt_clean_target(TARGET ${arg_NAME})

endmacro(blt_add_executable)


##------------------------------------------------------------------------------
## blt_add_test( NAME              [name]
##               COMMAND           [command] 
##               NUM_MPI_TASKS     [n]
##               NUM_OMP_THREADS   [n]
##               CONFIGURATIONS    [config1 [config2...]]
##               WORKING_DIRECTORY [dir])
##
## Adds a test to the project.
##------------------------------------------------------------------------------
macro(blt_add_test)

    set(options )
    set(singleValueArgs NAME NUM_MPI_TASKS NUM_OMP_THREADS WORKING_DIRECTORY)
    set(multiValueArgs COMMAND CONFIGURATIONS)

    # Parse the arguments to the macro
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    if ( NOT DEFINED arg_NAME )
        message(FATAL_ERROR "NAME is a required parameter to blt_add_test")
    endif()

    if ( NOT DEFINED arg_COMMAND )
        message(FATAL_ERROR "COMMAND is a required parameter to blt_add_test")
    endif()

    # Set default working directory if not set
    if ( NOT DEFINED arg_WORKING_DIRECTORY )
        set(_working_directory ${CMAKE_CURRENT_BINARY_DIR})
    else()
        set(_working_directory ${arg_WORKING_DIRECTORY})
    endif()

    # Extract test directory and executable from arg_NAME and arg_COMMAND
    set(_test_directory)
    if(NOT TARGET ${arg_NAME})
        # Handle cases where multiple tests are run against one executable
        # the NAME will not be the target
        list(GET arg_COMMAND 0 _test_executable)
        if(TARGET ${_test_executable})
            get_target_property(_test_directory ${_test_executable} RUNTIME_OUTPUT_DIRECTORY )
        endif()
    else()
        set(_test_executable ${arg_NAME})
        get_target_property(_test_directory ${arg_NAME} RUNTIME_OUTPUT_DIRECTORY )
    endif()
    
    # Append the test_directory to the test argument, accounting for multi-config generators
    if( NOT CMAKE_CONFIGURATION_TYPES )
        if(NOT "${_test_directory}" STREQUAL "")
            set(_test_command ${_test_directory}/${arg_COMMAND} )
        else()
            set(_test_command ${arg_COMMAND})
        endif()
    else()
        if( TARGET ${_test_executable} )
            list(INSERT arg_COMMAND 0 "$<TARGET_FILE:${_test_executable}>")
            list(REMOVE_AT arg_COMMAND 1)
        endif()
        set(_test_command ${arg_COMMAND})
    endif()

    # If configuration option ENABLE_WRAP_ALL_TESTS_WITH_MPIEXEC is set, 
    # ensure NUM_MPI_TASKS is at least one. This invokes the test 
    # through MPIEXEC.
    if ( ENABLE_WRAP_ALL_TESTS_WITH_MPIEXEC AND NOT arg_NUM_MPI_TASKS )
        set( arg_NUM_MPI_TASKS 1 )
    endif()

    # Handle MPI
    if( arg_NUM_MPI_TASKS )
        # first check that the number of ranks is a positive integer
        string(REGEX MATCH "^-?[0-9]+$" _is_integer "${arg_NUM_MPI_TASKS}")
        if( NOT _is_integer OR arg_NUM_MPI_TASKS LESS 1)
            message(FATAL_ERROR "In blt_add_test(), attempted to run an mpi test with invalid NUM_MPI_TASKS: ${arg_NUM_MPI_TASKS}")
        endif()

        # prefix command with mpi executable in MPI configs
        if( BLT_ENABLE_MPI)
            # Handle CMake changing MPIEXEC to MPIEXEC_EXECUTABLE
            if( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.10.0" )
                set(_mpiexec ${MPIEXEC_EXECUTABLE})
            else()
                set(_mpiexec ${MPIEXEC})
            endif()

            set(_test_command ${_mpiexec} ${MPIEXEC_NUMPROC_FLAG} ${arg_NUM_MPI_TASKS} ${BLT_MPI_COMMAND_APPEND} ${_test_command} )
        elseif( arg_NUM_MPI_TASKS EQUAL 1)
            # no-op: Allow NUM_MPI_TASKS to be 1 when not using MPI
        else()
            message(FATAL_ERROR "In blt_add_test(), attempted to invoke a test with ${arg_NUM_MPI_TASKS} ranks in a non-mpi configuration")
        endif()
    endif()

    add_test(NAME              ${arg_NAME}
             COMMAND           ${_test_command}
             CONFIGURATIONS    ${arg_CONFIGURATIONS}
             WORKING_DIRECTORY ${_working_directory})

    # Handle OpenMP
    if( arg_NUM_OMP_THREADS )
        set_property(TEST ${arg_NAME}
                     APPEND PROPERTY ENVIRONMENT OMP_NUM_THREADS=${arg_NUM_OMP_THREADS})
    endif()

endmacro(blt_add_test)


##------------------------------------------------------------------------------
## blt_add_benchmark( NAME              [name] 
##                    COMMAND           [command]
##                    NUM_MPI_TASKS     [n]
##                    NUM_OMP_THREADS   [n]
##                    CONFIGURATIONS    [config1 [config2...]]
##                    WORKING_DIRECTORY [dir])
##
## Adds a benchmark to the project.
##------------------------------------------------------------------------------
macro(blt_add_benchmark)

    set(options)
    set(singleValueArgs NAME NUM_MPI_TASKS NUM_OMP_THREADS WORKING_DIRECTORY)
    set(multiValueArgs COMMAND CONFIGURATIONS)

    ## parse the arguments to the macro
    cmake_parse_arguments(arg
     "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    # The 'CONFIGURATIONS Benchmark' line excludes benchmarks 
    # from the general list of tests
    blt_add_test( NAME              ${arg_NAME}
                  COMMAND           ${arg_COMMAND}
                  NUM_MPI_TASKS     ${arg_NUM_MPI_TASKS}
                  NUM_OMP_THREADS   ${arg_NUM_OMP_THREADS}
                  CONFIGURATIONS    Benchmark ${arg_CONFIGURATIONS}
                  WORKING_DIRECTORY ${arg_WORKING_DIRECTORY})

    # The 'LABELS Benchmark` prevents regular tests from
    # running when running benchmarks custom target
    set_tests_properties( ${arg_NAME}
                          PROPERTIES LABELS "Benchmark")

endmacro(blt_add_benchmark)


##------------------------------------------------------------------------------
## blt_append_custom_compiler_flag( 
##                    FLAGS_VAR  flagsVar       (required)
##                    DEFAULT    defaultFlag    (optional)
##                    GNU        gnuFlag        (optional)
##                    CLANG      clangFlag      (optional)
##                    INTEL      intelFlag      (optional)
##                    INTELLLVM  intelLLVMFlag  (optional)
##                    XL         xlFlag         (optional)
##                    MSVC       msvcFlag       (optional)
##                    MSVC_INTEL msvcIntelFlag  (optional)
##                    PGI        pgiFlag        (optional)
##                    CRAY       crayFlag       (optional))
##
## Appends compiler-specific flags to a given variable of flags
##------------------------------------------------------------------------------
macro(blt_append_custom_compiler_flag)

   set(options)
   set(singleValueArgs FLAGS_VAR DEFAULT GNU CLANG PGI INTEL INTELLLVM XL MSVC MSVC_INTEL CRAY)
   set(multiValueArgs)

   # Parse the arguments
   cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

   # Sanity check for required keywords
   if(NOT DEFINED arg_FLAGS_VAR)
      message( FATAL_ERROR "append_custom_compiler_flag macro requires FLAGS_VAR keyword and argument." )
   endif()

   # Set the desired flags based on the compiler family   
   # MSVC COMPILER FAMILY applies to C/C++ and Fortran
   string( TOLOWER ${arg_FLAGS_VAR} lower_flag_var )
   if( DEFINED arg_MSVC_INTEL AND COMPILER_FAMILY_IS_MSVC_INTEL )
      set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_MSVC_INTEL} " )
   elseif( DEFINED arg_MSVC AND (COMPILER_FAMILY_IS_MSVC OR COMPILER_FAMILY_IS_MSVC_INTEL) )
      set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_MSVC} " )
   
   #else, if we are setting a fortran flag, check against the fortran compiler family
   elseif ( ENABLE_FORTRAN AND ${lower_flag_var} MATCHES "fortran" )
       if( DEFINED arg_CLANG AND Fortran_COMPILER_FAMILY_IS_CLANG )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_CLANG} " )
       elseif( DEFINED arg_XL AND Fortran_COMPILER_FAMILY_IS_XL )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_XL} " )
       elseif( DEFINED arg_INTEL AND Fortran_COMPILER_FAMILY_IS_INTEL )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_INTEL} " )
       elseif( DEFINED arg_PGI AND Fortran_COMPILER_FAMILY_IS_PGI )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_PGI} " )
       elseif( DEFINED arg_GNU AND Fortran_COMPILER_FAMILY_IS_GNU )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_GNU} " )
       elseif( DEFINED arg_CRAY AND Fortran_COMPILER_FAMILY_IS_CRAY )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_CRAY} " )
       elseif( DEFINED arg_INTELLLVM AND Fortran_COMPILER_FAMILY_IS_INTELLLVM )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_INTELLLVM} " )
       elseif( DEFINED arg_DEFAULT )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_DEFAULT} ")
       endif()
  
   #else, we are setting a non MSVC C/C++ flag, check against the C family. 
   else()
       if( DEFINED arg_CLANG AND C_COMPILER_FAMILY_IS_CLANG )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_CLANG} " )
       elseif( DEFINED arg_XL AND C_COMPILER_FAMILY_IS_XL )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_XL} " )
       elseif( DEFINED arg_INTEL AND C_COMPILER_FAMILY_IS_INTEL )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_INTEL} " )
       elseif( DEFINED arg_INTELLLVM AND C_COMPILER_FAMILY_IS_INTELLLVM )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_INTELLLVM} " )
       elseif( DEFINED arg_PGI AND C_COMPILER_FAMILY_IS_PGI )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_PGI} " )
       elseif( DEFINED arg_GNU AND C_COMPILER_FAMILY_IS_GNU )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_GNU} " )
       elseif( DEFINED arg_CRAY AND C_COMPILER_FAMILY_IS_CRAY )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_CRAY} " )
       elseif( DEFINED arg_DEFAULT )
          set (${arg_FLAGS_VAR} "${${arg_FLAGS_VAR}} ${arg_DEFAULT} ")
       endif()
   endif()
   unset(lower_flag_var)

endmacro(blt_append_custom_compiler_flag)


##------------------------------------------------------------------------------
## blt_find_libraries( FOUND_LIBS <FOUND_LIBS variable name>
##                     NAMES      [libname1 [libname2 ...]]
##                     REQUIRED   [TRUE (default) | FALSE ]
##                     PATHS      [path1 [path2 ...]] )
##
## This command is used to find a list of libraries.
##------------------------------------------------------------------------------
macro(blt_find_libraries)

    set(options )
    set(singleValueArgs FOUND_LIBS REQUIRED )
    set(multiValueArgs NAMES PATHS )

    ## parse the arguments
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    if ( NOT DEFINED arg_FOUND_LIBS )
        message(FATAL_ERROR "The blt_find_libraries required parameter FOUND_LIBS specifies the list that found libraries will be appended to.")
    endif()

    if ( NOT DEFINED arg_NAMES )
        message(FATAL_ERROR "The blt_find_libraries required parameter NAMES specifies the library names you are searching for.")
    endif()

    if ( NOT DEFINED arg_PATHS )
        message(FATAL_ERROR "The blt_find_libraries required parameter PATHS specifies the paths to search for NAMES.")
    endif()

    if ( NOT DEFINED arg_REQUIRED)
        set(arg_REQUIRED TRUE)
    endif()

    foreach( lib ${arg_NAMES} )
        unset( temp CACHE )
        find_library( temp NAMES ${lib}
                      PATHS ${arg_PATHS}
                      NO_DEFAULT_PATH
                      NO_CMAKE_ENVIRONMENT_PATH
                      NO_CMAKE_PATH
                      NO_SYSTEM_ENVIRONMENT_PATH
                      NO_CMAKE_SYSTEM_PATH)
        if( temp )
            list( APPEND ${arg_FOUND_LIBS} ${temp} )
        elseif (${arg_REQUIRED})
            message(FATAL_ERROR "blt_find_libraries required NAMES entry ${lib} not found. These are not the libs you are looking for.")
        endif()
    endforeach()

endmacro(blt_find_libraries)


##------------------------------------------------------------------------------
## blt_combine_static_libraries( NAME <libname>
##                               SOURCE_LIBS [lib1 ...] 
##                               LIB_TYPE [STATIC,SHARED]
##                               LINK_PREPEND []
##                               LINK_POSTPEND [])
##
## Adds a library target, called <libname>, to be built from the set of 
## static libraries given in SOURCE_LIBS.
## 
## The LINK_PREPEND argument will be prepended to the library on the link line,
## while the LINK_POSTPEND will be appended to the library on the link line.
## These values are defaulted to the appropriate values for CMAKE_HOST_APPLE and 
## CMAKE_HOST_UNIX.
##
## Note: This macro does not currently work for Windows
##
##------------------------------------------------------------------------------
macro(blt_combine_static_libraries)

    set(options )
    set(singleValueArgs NAME LINK_PREPEND LINK_POSTPEND LIB_TYPE )
    set(multiValueArgs SOURCE_LIBS )

    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    # Sanity checks
    if( "${arg_NAME}" STREQUAL "" )
        message(FATAL_ERROR "blt_combine_static_libraries() must be called with argument NAME <name>")
    endif()

    if(TARGET ${arg_NAME})
        message(FATAL_ERROR "A target with the name ${arg_NAME} already exists!")
    endif()

    if( NOT arg_SOURCE_LIBS )
        message(FATAL_ERROR "blt_combine_static_libraries(NAME ${arg_NAME} ...) called with no given source libraries")
    endif()
    
    # Default linker flags if not given
    if( NOT arg_LINK_PREPEND )
        if( CMAKE_HOST_APPLE )
            set( _link_prepend "-Wl,-force_load" )
        elseif( CMAKE_HOST_UNIX )
            set( _link_prepend "-Wl,--whole-archive" )
        elseif( CMAKE_HOST_WIN32 )
            # This used to work. Needs to be fixed
            # set( _link_prepend "-WHOLEARCHIVE:" )
            message(FATAL_ERROR "blt_combine_static_libraries does not support ${CMAKE_HOST_SYSTEM}")
        else()
            message(FATAL_ERROR "blt_combine_static_libraries does not support ${CMAKE_HOST_SYSTEM}")
        endif()
    else()
        set( _link_prepend ${arg_LINK_PREPEND})
    endif()

    if( NOT arg_LINK_POSTPEND )
        if( CMAKE_HOST_APPLE )
            set( _link_postpend "" )
        elseif( CMAKE_HOST_UNIX )
            set( _link_postpend "-Wl,--no-whole-archive" )
        elseif( CMAKE_HOST_WIN32 )
            set( _link_postpend "" )
        else()
            message(FATAL_ERROR "blt_combine_static_libraries does not support ${CMAKE_HOST_SYSTEM}")
        endif()
    else()
        set( _link_postpend ${arg_LINK_POSTPEND})
    endif()
    
    # Create link line that has all the libraries to combine on it
    set( libLinkLine "" )
    foreach( lib ${arg_SOURCE_LIBS} )
        if( CMAKE_HOST_UNIX )
            list( APPEND libLinkLine ${_link_prepend} ${lib} ${_link_postpend} )
        elseif( CMAKE_HOST_WIN32 )
            list( APPEND libLinkLine "${_link_prepend}${lib}" )
        endif()
    endforeach()

    # Decide if the created library is static or shared
    if( ${arg_LIB_TYPE} STREQUAL "STATIC" )
        set( _lib_type STATIC )
    elseif( ${arg_LIB_TYPE} STREQUAL "SHARED" ) 
        set( _lib_type SHARED )
    else()
        message(FATAL_ERROR "blt_combine_static_libraries(NAME ${arg_NAME} ...) LIB_TYPE must be SHARED OR STATIC")
    endif()
    
    # Create new library with empty source file
    add_library( ${arg_NAME} ${_lib_type}
                 ${BLT_ROOT_DIR}/tests/internal/src/combine_static_library_test/dummy.cpp)

    # Add the combined link line flag
    target_link_libraries( ${arg_NAME} PRIVATE ${libLinkLine})

    # Add the includes that should be inherited from themselves and their dependencies
    set( interface_include_directories "" )
    set( interface_system_include_directories "" )
    foreach( source_lib ${arg_SOURCE_LIBS} )
    
        get_target_property( source_lib_system_include_directories 
                             ${source_lib} 
                             INTERFACE_SYSTEM_INCLUDE_DIRECTORIES )

        if( source_lib_system_include_directories )
            list( APPEND interface_system_include_directories
                         ${source_lib_system_include_directories} )
        endif()

        get_target_property( source_lib_include_directories 
                             ${source_lib} 
                             INTERFACE_INCLUDE_DIRECTORIES )
        
        if( source_lib_include_directories )
            list( APPEND interface_include_directories ${source_lib_include_directories} )
        endif()

        # Get all includes from the dependencies of the libraries to be combined
        get_target_property( interface_link_libs ${source_lib} INTERFACE_LINK_LIBRARIES )        
        foreach( interface_link_lib ${interface_link_libs} )
            # Filter out non-CMake targets
            if( TARGET ${interface_link_lib} )
                get_target_property( interface_link_lib_include_dir 
                                     ${interface_link_lib} 
                                     INTERFACE_INCLUDE_DIRECTORIES )
                                     
                if( interface_link_lib_include_dir )
                    list( APPEND interface_include_directories ${interface_link_lib_include_dir} )
                endif()

                get_target_property( interface_link_lib_system_include_dir 
                                     ${interface_link_lib} 
                                     INTERFACE_SYSTEM_INCLUDE_DIRECTORIES )
                                     
                if( interface_link_lib_system_include_dir )
                    list( APPEND interface_system_include_directories
                                 ${interface_link_lib_system_include_dir} )
                endif()

                get_target_property( target_type ${interface_link_lib}  TYPE )
                if( target_type STREQUAL "SHARED_LIBRARY" )
                     target_link_libraries( ${arg_NAME} PUBLIC ${interface_link_lib} )
                endif ()

            elseif( ${interface_link_lib} MATCHES ".so" OR 
                    ${interface_link_lib} MATCHES ".dll" OR 
                    ${interface_link_lib} MATCHES ".dylib" )
                # Add any shared libraries that were added by file name
                target_link_libraries( ${arg_NAME} PUBLIC ${interface_link_lib} )
            endif()            
        endforeach()
    endforeach()
    
    # Remove duplicates from the includes
    blt_list_remove_duplicates(TO interface_include_directories )
    blt_list_remove_duplicates(TO interface_system_include_directories )

    # Remove any system includes from the regular includes
    foreach( include_dir ${interface_system_include_directories} )
        if( ${include_dir} IN_LIST interface_include_directories )
            list( REMOVE_ITEM interface_include_directories ${include_dir} )
        endif()
    endforeach()

    target_include_directories( ${arg_NAME} INTERFACE
                                ${interface_include_directories} )

    target_include_directories( ${arg_NAME} SYSTEM INTERFACE
                                ${interface_system_include_directories} )

    unset( libLinkLine )
    unset( interface_include_directories )
    unset( interface_system_include_directories )
    unset( interface_link_lib_include_dir )
    unset( source_lib_include_directories )
    unset( _lib_type )
    unset( _link_prepend )
    unset( _link_postpend )
endmacro(blt_combine_static_libraries)


##------------------------------------------------------------------------------
## blt_print_target_properties(TARGET     <target name>
##                             CHILDREN   <TRUE|FALSE>
##                             PROPERTY_NAME_REGEX <regular_expression_string>
##                             PROPERTY_VALUE_REGEX <regular_expression_string>)
##
## Prints all (or filtered) properties of a given target and optionally its
## dependencies as well.
##
## Has the options to print target's link libraries and interface link libraries
## with the CHILDREN argument, as well as specific properties using regular
## expressions.
## 
## Defaults:
## CHILDREN = false (non recursive)
## PROPERTY_NAME_REGEX = .* (print every property name)
## PROPERTY_VALUE_REGEX = .* (print every property value)
## 
##------------------------------------------------------------------------------
macro(blt_print_target_properties)

    set(options)
    set(singleValuedArgs TARGET CHILDREN PROPERTY_NAME_REGEX PROPERTY_VALUE_REGEX)
    set(multiValuedArgs)

    # parse the arguments to the macro
    cmake_parse_arguments(arg
         "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN})

    # check for required arguments
    if(NOT DEFINED arg_TARGET)
        message(FATAL_ERROR "TARGET is a required parameter for the blt_print_target_properties macro")
    endif()

    # set default values
    if(NOT DEFINED arg_CHILDREN)
        set(arg_CHILDREN FALSE)
    endif()

    if(NOT DEFINED arg_PROPERTY_NAME_REGEX)
        set(arg_PROPERTY_NAME_REGEX ".*")
    endif()

    if(NOT DEFINED arg_PROPERTY_VALUE_REGEX)
        set(arg_PROPERTY_VALUE_REGEX ".*")
    endif()

    # check if this is a valid cmake target or blt_registered target
    set(_is_cmake_target FALSE)
    if(TARGET ${arg_TARGET})
        set(_is_cmake_target TRUE)
    endif()

    set(_is_blt_registered_target FALSE)
    string(TOUPPER ${arg_TARGET} _target_upper)
    if(_BLT_${_target_upper}_IS_REGISTERED_LIBRARY)
        set(_is_blt_registered_target TRUE)
    endif()

    if(NOT _is_cmake_target AND NOT _is_blt_registered_target)
        message (STATUS "[blt_print_target_properties] Invalid argument '${arg_TARGET}'."
                         "This macro applies only to valid cmake targets or blt_registered targets.")
    else()
        # print properties
        blt_print_target_properties_private(TARGET ${arg_TARGET}
                                            PROPERTY_NAME_REGEX ${arg_PROPERTY_NAME_REGEX}
                                            PROPERTY_VALUE_REGEX ${arg_PROPERTY_VALUE_REGEX})

        if(${arg_CHILDREN})
            # find all targets from dependency tree
            set(tlist "")
            blt_find_target_dependencies(TARGET ${arg_TARGET} TLIST tlist)
            blt_list_remove_duplicates(TO tlist)

            # print all targets from dependency tree
            foreach(t ${tlist})
                blt_print_target_properties_private(TARGET ${t}
                                                    PROPERTY_NAME_REGEX ${arg_PROPERTY_NAME_REGEX}
                                                    PROPERTY_VALUE_REGEX ${arg_PROPERTY_VALUE_REGEX})
            endforeach()
            unset(tlist)
        endif()
    endif()

    unset(_target_upper)
    unset(_is_blt_registered_target)
    unset(_is_cmake_target)
endmacro(blt_print_target_properties)


##------------------------------------------------------------------------------
## blt_print_variables([NAME_REGEX  <regular_expression_string>]
##                     [VALUE_REGEX <regular_expression_string>]
##                     [IGNORE_CASE])
##
## Prints all (or filtered) variables and their values in the current scope.
## 
## Defaults:
## The regexes are case-sensitive unless the IGNORE_CASE option is supplied
## NAME_REGEX = .* (print every property name)
## VALUE_REGEX = .* (print every property value)
## 
##------------------------------------------------------------------------------
macro(blt_print_variables)

    set(options            IGNORE_CASE)
    set(singleValuedArgs   NAME_REGEX VALUE_REGEX)
    set(multiValuedArgs)

    # parse and initialize arguments to the macro
    cmake_parse_arguments(arg
         "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN})


    message(STATUS "[blt_print_variables] The following variables are defined at the calling site in '${CMAKE_CURRENT_LIST_FILE}' -- ")

    if(NOT DEFINED arg_IGNORE_CASE)
        set(arg_IGNORE_CASE FALSE)
    endif()

    if(arg_IGNORE_CASE)
        set(_case_sensitivity "case insensitive")
    else()
        set(_case_sensitivity "case sensitive")
    endif()

    if(DEFINED arg_NAME_REGEX)
        message(STATUS "[blt_print_variables] matching NAME_REGEX '${arg_NAME_REGEX}' (${_case_sensitivity})")
    else()
        set(arg_NAME_REGEX ".*")
    endif()

    if(DEFINED arg_VALUE_REGEX)
        message(STATUS "[blt_print_variables] matching VALUE_REGEX '${arg_VALUE_REGEX}' (${_case_sensitivity})")
    else()
        set(arg_VALUE_REGEX ".*")
    endif()


    # Note: 'if(DEFINED CACHE{var})' is only avaliable in CMake@3.14+
    set(_has_defined_cache FALSE)
    if( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.14.0")
        set(_has_defined_cache TRUE)
    endif()

    # Start with a sorted, unique list of all variables
    get_cmake_property(_vars VARIABLES)
    list (SORT _vars)
    list (REMOVE_DUPLICATES _vars)

    # Filter and print each variable
    foreach (_v ${_vars})
        # Apply regex to variable name, accounting for case sensitivity
        set(_match_name FALSE)
        if(arg_IGNORE_CASE)
            string(TOUPPER ${_v} _v_upper)
            string(REGEX MATCH ${arg_NAME_REGEX} _match_upper ${_v_upper})

            string(TOLOWER ${_v} _v_lower)
            string(REGEX MATCH ${arg_NAME_REGEX} _match_lower ${_v_lower})

            if(_match_upper OR _match_lower)
                set(_match_name TRUE)
            endif()
        else()
            string(REGEX MATCH ${arg_NAME_REGEX} _match_name ${_v})
        endif()

        # Apply regex to variable value, accounting for case sensitivity
        # Optimization: Only apply VALUE_REGEX to matched names
        # Practicality: Only apply VALUE_REGEX to non-empty variables. 
        # This avoids the following CMake error:
        #     "string sub-command REGEX, mode MATCH regex ".*" matched an empty string"
        set(_match_value FALSE)
        if(_match_name AND ${_v})
            set(_val "${${_v}}")
            if(arg_IGNORE_CASE)
                string(TOUPPER "${_val}" _val_upper)
                string(REGEX MATCH ${arg_VALUE_REGEX} _match_upper "${_val_upper}")

                string(TOLOWER "${_val}" _val_lower)
                string(REGEX MATCH ${arg_VALUE_REGEX} _match_lower "${_val_lower}")

                if(_match_upper OR _match_lower)
                    set(_match_value TRUE)
                endif()
            else()
                string(REGEX MATCH ${arg_VALUE_REGEX} _match_value "${_val}")
            endif()
        endif()

        # Format variable name and value and print
        if (_match_name AND _match_value)
            set(_v_print_name ${_v})
            # If it's a cache variable, wrap in "CACHE{}"
            if(_has_defined_cache AND DEFINED CACHE{${_v}})
                # Append TYPE to cache variable name, if non-empty
                get_property(_type CACHE ${_v} PROPERTY TYPE)
                if(NOT "" STREQUAL "${_type}")
                    set(_v_print_name "CACHE{${_v}}:${_type}")
                else()
                    set(_v_print_name "CACHE{${_v}}")
                endif()
            endif()
            
            message(STATUS "[blt_print_variables]   ${_v_print_name} := ${${_v}}")
        endif()
    endforeach()

    message(STATUS "[blt_print_variables] ----------------------------------------------------------")

    unset(_case_sensitive)
    unset(_vars)
    unset(_has_defined_cache)
    unset(_match_name)
    unset(_match_value)
endmacro(blt_print_variables)

# The following variables control whether third-party libraries (TPLs) should have targets exported from  
# a project using BLT, or if the TPLs should be configured downstream and have their setup CMake files 
# installed.  These are set by calling either blt_install_tpl_setups or blt_export_tpl_targets.
set(_BLT_EXPORT_TPL_TARGETS FALSE)
mark_as_advanced(_BLT_EXPORT_TPL_TARGETS)
set(_BLT_INSTALL_TPL_SETUPS FALSE)
mark_as_advanced(_BLT_INSTALL_TPL_SETUPS)

##------------------------------------------------------------------------------
## blt_export_tpl_targets(EXPORT <export-set> NAMESPACE <namespace>)
##
## Add targets for BLT's third-party libraries to the given export-set, prefixed
## with the provided namespace.
##------------------------------------------------------------------------------
macro(blt_export_tpl_targets)
    set(options)
    set(singleValuedArgs NAMESPACE EXPORT)
    set(multiValuedArgs)

    ## parse the arguments to the macro
    cmake_parse_arguments(arg
         "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN})

    if(NOT DEFINED arg_EXPORT)
        message(FATAL_ERROR "EXPORT is a required parameter for the blt_export_tpl_targets macro.")
    endif()

    if(_BLT_INSTALL_TPL_SETUPS)
        message(FATAL_ERROR "TPL setup files have already been installed using blt_install_tpl_setups.  
                             TPL libraries cannot be both exported and installed.")
    endif()
    # Set the variable indicating that TPL libraries will be exported to guard against users
    # simultaneously exporting and installing flexible TPL targets.
    set(_BLT_EXPORT_TPL_TARGETS TRUE)

    set(_blt_tpl_targets)
    blt_list_append(TO _blt_tpl_targets ELEMENTS cuda cuda_runtime IF BLT_ENABLE_CUDA)
    blt_list_append(TO _blt_tpl_targets ELEMENTS blt_hip blt_hip_runtime IF BLT_ENABLE_HIP)
    blt_list_append(TO _blt_tpl_targets ELEMENTS openmp IF BLT_ENABLE_OPENMP)
    blt_list_append(TO _blt_tpl_targets ELEMENTS mpi IF BLT_ENABLE_MPI)
    
    foreach(dep ${_blt_tpl_targets})
        # If the target is EXPORTABLE, add it to the export set
        get_target_property(_is_imported ${dep} IMPORTED)
        if(NOT ${_is_imported})
            install(TARGETS              ${dep}
                    EXPORT               ${arg_EXPORT})
            # Namespace target to avoid conflicts
            if (DEFINED arg_NAMESPACE)
                set_target_properties(${dep} PROPERTIES EXPORT_NAME ${arg_NAMESPACE}::${dep})
            endif ()
        endif()
    endforeach()
endmacro()

##------------------------------------------------------------------------------
## blt_install_tpl_setups(DESTINATION <path relative to your install prefix>)
##
## Install CMake config files for third-party libraries.  This macro should be called
## whenever a project uses a third-party library like CUDA, MPI, OpenMP, or HIP.  It is
## a more correct way to configure third-party libraries than blt_export_tpl_targets,
## because compile flags and link flags can be set at config time by downstream 
## libraries.
## 
##------------------------------------------------------------------------------
macro(blt_install_tpl_setups)
    set(singleValuedArgs DESTINATION)
    cmake_parse_arguments(arg
         "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN})

    if(NOT DEFINED arg_DESTINATION)
        message(FATAL_ERROR "DESTINATION is a required parameter for the blt_install_tpl_setups macro.")
    endif()

    if(_BLT_EXPORT_TPL_TARGETS)
        message(FATAL_ERROR "TPL targets have already been exported using blt_export_tpl_targets.  
                             TPL libraries cannot be both exported and installed.")
    endif()
    # Set the variable indicating that TPL libraries will have their config files installed 
    # to guard against users simultaneously exporting and installing flexible TPL targets.
    set(_BLT_INSTALL_TPL_SETUPS TRUE)

    # SetupThirdPartyTargetsDownstream.cmake will include the third-party library config
    # files if necessary.  Installing this into the project's cmake directory enables
    # this to occur during config time in downstream projects, instead of
    # during BLT's configuration.
    install(FILES ${BLT_ROOT_DIR}/cmake/BLTSetupTargets.cmake
            DESTINATION ${arg_DESTINATION})
    install(FILES ${BLT_ROOT_DIR}/cmake/BLTInstallableMacros.cmake
            DESTINATION ${arg_DESTINATION})

    configure_file(
        ${BLT_ROOT_DIR}/cmake/BLTThirdPartyConfigFlags.cmake.in
        ${BLT_BUILD_DIR}/BLTThirdPartyConfigFlags.cmake
        @ONLY
    )

    install(FILES ${BLT_BUILD_DIR}/BLTThirdPartyConfigFlags.cmake
        DESTINATION ${arg_DESTINATION})

    set(_blt_tpl_configs)
    blt_list_append(TO _blt_tpl_configs ELEMENTS ${BLT_ROOT_DIR}/cmake/thirdparty/BLTSetupCUDA.cmake IF BLT_ENABLE_CUDA)
    blt_list_append(TO _blt_tpl_configs ELEMENTS ${BLT_ROOT_DIR}/cmake/thirdparty/BLTSetupHIP.cmake IF BLT_ENABLE_HIP)
    blt_list_append(TO _blt_tpl_configs ELEMENTS ${BLT_ROOT_DIR}/cmake/thirdparty/BLTSetupOpenMP.cmake IF BLT_ENABLE_OPENMP)
    blt_list_append(TO _blt_tpl_configs ELEMENTS ${BLT_ROOT_DIR}/cmake/thirdparty/BLTSetupMPI.cmake IF BLT_ENABLE_MPI)

    if (_blt_tpl_configs) 
        install(DIRECTORY DESTINATION ${arg_DESTINATION}/thirdparty)
    endif()

    foreach(config_file ${_blt_tpl_configs})
        install(FILES ${config_file}
                DESTINATION ${arg_DESTINATION}/thirdparty)
    endforeach()

endmacro()

##------------------------------------------------------------------------------
## blt_check_code_compiles(CODE_COMPILES <variable>
##                         VERBOSE_OUTPUT <ON|OFF (default OFF)>
##                         DEPENDS_ON <libs>
##                         SOURCE_STRING <quoted C++ program>)
##
## This macro checks if a snippet of C++ code compiles.
##
## SOURCE_STRING The source snippet to compile.
## Must be a valid C++ program with a main() function.
## Note: This parameter should be passed in as a quoted string variable. Otherwise,
## cmake will convert the string into a list and lose the semicolons.
## E.g. blt_check_code_compiles(SOURCE_STRING "${str_var}" ...)
##
## CODE_COMPILES A boolean variable the contains the compilation result.
##
## VERBOSE_OUTPUT Optional parameter to output debug information (Default: off)
##
## DEPENDS_ON Optional parameter for a list of additional dependencies
##------------------------------------------------------------------------------
macro(blt_check_code_compiles)

    set(options)
    set(singleValueArgs CODE_COMPILES VERBOSE_OUTPUT )
    # NOTE: SOURCE_STRING must be a multiValueArg otherwise CMake removes all semi-colons
    set(multiValueArgs DEPENDS_ON SOURCE_STRING)

    # Parse the arguments to the macro
    cmake_parse_arguments(arg
         "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN})

    # Check the arguments
    if(NOT DEFINED arg_SOURCE_STRING)
        message(FATAL_ERROR "blt_check_code_compiles() requires SOURCE_STRING to be specified")
    endif()

    if(NOT DEFINED arg_CODE_COMPILES)
        message(FATAL_ERROR "blt_check_code_compiles() requires CODE_COMPILES to be specified")
    endif()

    if(NOT DEFINED arg_VERBOSE_OUTPUT)
        set(arg_VERBOSE_OUTPUT FALSE)
    endif()

    if(${arg_VERBOSE_OUTPUT})
        message(STATUS "[blt_check_code_compiles] Attempting to compile source string: \n${arg_SOURCE_STRING}")
    endif()

    # Write string as temp file, try to compile it and then remove file
    string(RANDOM LENGTH 5 _rand)
    set(_fname ${CMAKE_CURRENT_BINARY_DIR}/_bltCheckCompiles${_rand}.cpp)
    file(WRITE ${_fname} "${arg_SOURCE_STRING}")
    if(NOT DEFINED arg_DEPENDS_ON)
        try_compile(${arg_CODE_COMPILES}
                ${CMAKE_CURRENT_BINARY_DIR}/CMakeTmp
                SOURCES ${_fname}
                CXX_STANDARD ${CMAKE_CXX_STANDARD}
                OUTPUT_VARIABLE _res)
    else()

        if(${CMAKE_VERSION} VERSION_LESS "3.28.0")
            # Workaround CMake bug where try_compile doesn't work with alias targets
            set(_deps)
            foreach(_dep ${arg_DEPENDS_ON})
                get_target_property(_real_target ${_dep} ALIASED_TARGET)
                if (NOT _real_target)
                    list(APPEND _deps ${_dep})
                else()
                    list(APPEND _deps ${_real_target})
                endif()
            endforeach()
        else()
            set(_deps {arg_DEPENDS_ON})
        endif()

        try_compile(${arg_CODE_COMPILES}
                ${CMAKE_CURRENT_BINARY_DIR}/CMakeTmp
                SOURCES ${_fname}
                CXX_STANDARD ${CMAKE_CXX_STANDARD}
                LINK_LIBRARIES ${_deps}
                OUTPUT_VARIABLE _res)
    endif()
    file(REMOVE ${_fname})

    if(${arg_VERBOSE_OUTPUT})
        message(STATUS "[blt_check_code_compiles] Compiler output: \n${_res}\n")

        if(${arg_CODE_COMPILES})
            message(STATUS "[blt_check_code_compiles] The code snippet successfully compiled")
        else()
            message(STATUS "[blt_check_code_compiles] The code snippet failed to compile")
        endif()
    endif()

    # clear the variables set within the macro
    unset(_fname)
    unset(_res)

endmacro(blt_check_code_compiles)
