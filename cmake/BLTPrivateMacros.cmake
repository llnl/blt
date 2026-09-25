# Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
#
# SPDX-License-Identifier: (BSD-3-Clause)

include(${BLT_ROOT_DIR}/cmake/BLTInstallableMacros.cmake)
include(CMakeParseArguments)

## Internal BLT CMake Macros

##-----------------------------------------------------------------------------
## blt_error_if_target_exists()
##
## Checks if target already exists in CMake project and errors out with given
## error_msg.
##-----------------------------------------------------------------------------
function(blt_error_if_target_exists target_name error_msg)
    if (TARGET ${target_name})
        message(FATAL_ERROR "${error_msg}Duplicate target name: ${target_name}")
    endif()
endfunction()


##-----------------------------------------------------------------------------
## blt_find_executable(NAME         <name of program to find>
##                     EXECUTABLES  [exe1 [exe2 ...]])
##
## This macro attempts to find the given executable via either a previously defined
## <UPPERCASE_NAME>_EXECUTABLE or using find_program with the given EXECUTABLES.
## if EXECUTABLES is left empty, then NAME is used.  This macro will only attempt
## to locate the executable if <UPPERCASE_NAME>_ENABLED is TRUE.
##
## If successful the following variables will be defined:
## <UPPERCASE_NAME>_FOUND
## <UPPERCASE_NAME>_EXECUTABLE
##-----------------------------------------------------------------------------
macro(blt_find_executable)

    set(options)
    set(singleValueArgs NAME)
    set(multiValueArgs  EXECUTABLES)

    # Parse the arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                        "${multiValueArgs}" ${ARGN} )

    # Check arguments
    if ( NOT DEFINED arg_NAME )
        message( FATAL_ERROR "Must provide a NAME argument to the 'blt_find_executable' macro" )
    endif()

    string(TOUPPER ${arg_NAME} _ucname)

    message(STATUS "${arg_NAME} support is ${ENABLE_${_ucname}}")
    if (ENABLE_${_ucname})
        set(_exes ${arg_NAME})
        if (DEFINED arg_EXECUTABLES)
            set(_exes ${arg_EXECUTABLES})
        endif()

        if (${_ucname}_EXECUTABLE)
            if (NOT EXISTS ${${_ucname}_EXECUTABLE})
                message(FATAL_ERROR "User defined ${_ucname}_EXECUTABLE (${${_ucname}_EXECUTABLE}) does not exist. Fix/unset variable or set ENABLE_${_ucname} to OFF.")
            endif()
        else()
            find_program(${_ucname}_EXECUTABLE
                         NAMES ${_exes}
                         DOC "Path to ${arg_NAME} executable")
        endif()

        # Handle REQUIRED and QUIET arguments
        # this will also set ${_ucname}_FOUND to true if ${_ucname}_EXECUTABLE exists
        include(FindPackageHandleStandardArgs)
        find_package_handle_standard_args(${arg_NAME}
                                          "Failed to locate ${arg_NAME} executable"
                                          ${_ucname}_EXECUTABLE)
    endif()
endmacro(blt_find_executable)


##------------------------------------------------------------------------------
## blt_expand_depends( DEPENDS_ON [dep1 ...]
##                     RESULT [variable] )
##------------------------------------------------------------------------------
macro(blt_expand_depends)
    set(options)
    set(singleValueArgs RESULT)
    set(multiValueArgs DEPENDS_ON)

    # Parse the arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                        "${multiValueArgs}" ${ARGN} )

    # Expand dependency list
    set(_deps_to_process ${arg_DEPENDS_ON})
    set(_expanded_DEPENDS_ON)
    while(_deps_to_process)
        # Copy the current set of dependencies to process
        set(_current_deps_to_process ${_deps_to_process})
        # and add them to the full expanded list
        list(APPEND _expanded_DEPENDS_ON ${_deps_to_process})
        # Then clear it so we can check if new ones were added
        set(_deps_to_process)
        foreach( dependency ${_current_deps_to_process} )
            string(TOUPPER ${dependency} uppercase_dependency )
            if ( DEFINED _BLT_${uppercase_dependency}_DEPENDS_ON )
                foreach(new_dependency ${_BLT_${uppercase_dependency}_DEPENDS_ON})
                    # Don't add duplicates
                    if (NOT ${new_dependency} IN_LIST _expanded_DEPENDS_ON)
                        list(APPEND _deps_to_process ${new_dependency})
                    endif()
                endforeach()
            endif()
        endforeach()
    endwhile()

    # Write the output to the requested variable
    set(${arg_RESULT} ${_expanded_DEPENDS_ON})
endmacro()


##------------------------------------------------------------------------------
## blt_setup_target( NAME       [name]
##                   DEPENDS_ON [dep1 ...]
##                   OBJECT     [TRUE | FALSE])
##------------------------------------------------------------------------------
macro(blt_setup_target)

    set(options)
    set(singleValueArgs NAME OBJECT)
    set(multiValueArgs DEPENDS_ON)

    # Parse the arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                        "${multiValueArgs}" ${ARGN} )

    # Check arguments
    if ( NOT DEFINED arg_NAME )
        message( FATAL_ERROR "Must provide a NAME argument to the 'blt_setup_target' macro" )
    endif()

    # Default to "real" scope, unless it's an interface library
    set(_private_scope PRIVATE)
    set(_public_scope  PUBLIC)
    get_target_property(_target_type ${arg_NAME} TYPE)
    if("${_target_type}" STREQUAL "INTERFACE_LIBRARY")
        set(_private_scope INTERFACE)
        set(_public_scope  INTERFACE)
    endif()

    # Expand dependency list - avoid "recalculating" if the information already exists
    set(_expanded_DEPENDS_ON)
    if(NOT "${_target_type}" STREQUAL "INTERFACE_LIBRARY")
        get_target_property(_expanded_DEPENDS_ON ${arg_NAME} BLT_EXPANDED_DEPENDENCIES)
    endif()
    if(NOT _expanded_DEPENDS_ON)
        blt_expand_depends(DEPENDS_ON ${arg_DEPENDS_ON} RESULT _expanded_DEPENDS_ON)
    endif()

    # Add dependency's information
    foreach( dependency ${_expanded_DEPENDS_ON} )
        string(TOUPPER ${dependency} uppercase_dependency )

        if ( NOT arg_OBJECT AND _BLT_${uppercase_dependency}_IS_OBJECT_LIBRARY )
            target_sources(${arg_NAME} ${_private_scope} $<TARGET_OBJECTS:${dependency}>)
        endif()

        if ( DEFINED _BLT_${uppercase_dependency}_INCLUDES )
            if ( _BLT_${uppercase_dependency}_TREAT_INCLUDES_AS_SYSTEM )
                target_include_directories( ${arg_NAME} SYSTEM ${_public_scope}
                    ${_BLT_${uppercase_dependency}_INCLUDES} )
            else()
                target_include_directories( ${arg_NAME} ${_public_scope}
                    ${_BLT_${uppercase_dependency}_INCLUDES} )
            endif()
        endif()

        if ( DEFINED _BLT_${uppercase_dependency}_FORTRAN_MODULES )
            target_include_directories( ${arg_NAME} ${_public_scope}
                ${_BLT_${uppercase_dependency}_FORTRAN_MODULES} )
        endif()

        if ( arg_OBJECT )
            # Object libraries need to inherit info from their CMake targets listed
            # in their LIBRARIES
            foreach( _library ${_BLT_${uppercase_dependency}_LIBRARIES} )
                if(TARGET ${_library})
                    blt_inherit_target_info(TO     ${arg_NAME}
                                            FROM   ${_library}
                                            OBJECT ${arg_OBJECT})
                endif()
            endforeach()
        endif()

        if ( arg_OBJECT OR _BLT_${uppercase_dependency}_IS_OBJECT_LIBRARY )
            # We want object libraries to inherit the vital info but not call
            # target_link_libraries() otherwise you have to install the object
            # files associated with the object library which noone wants.
            if ( TARGET ${dependency} )
                blt_inherit_target_info(TO     ${arg_NAME}
                                        FROM   ${dependency}
                                        OBJECT ${arg_OBJECT})
            endif()
        elseif (DEFINED _BLT_${uppercase_dependency}_LIBRARIES)
            # This prevents cmake from adding -l<library name> to the
            # command line for BLT registered libraries which are not
            # actual CMake targets
            if(NOT "${_BLT_${uppercase_dependency}_LIBRARIES}"
                    STREQUAL "BLT_NO_LIBRARIES" )
                target_link_libraries( ${arg_NAME} ${_public_scope}
                    ${_BLT_${uppercase_dependency}_LIBRARIES} )
            endif()
        else()
            target_link_libraries( ${arg_NAME} ${_public_scope} ${dependency} )
        endif()

        if ( DEFINED _BLT_${uppercase_dependency}_DEFINES )
            target_compile_definitions( ${arg_NAME} ${_public_scope}
                ${_BLT_${uppercase_dependency}_DEFINES} )
        endif()

        if ( DEFINED _BLT_${uppercase_dependency}_COMPILE_FLAGS )
            blt_add_target_compile_flags(TO ${arg_NAME}
                                         FLAGS ${_BLT_${uppercase_dependency}_COMPILE_FLAGS} )
        endif()

        if ( NOT arg_OBJECT AND DEFINED _BLT_${uppercase_dependency}_LINK_FLAGS )
            blt_add_target_link_flags(TO ${arg_NAME}
                                      FLAGS ${_BLT_${uppercase_dependency}_LINK_FLAGS} )
        endif()

        if(TARGET ${dependency})
            # If it's an interface library CMake doesn't even allow us to query the property
            get_target_property(_dep_type ${dependency} TYPE)
            if(NOT "${_dep_type}" STREQUAL "INTERFACE_LIBRARY")
                # Propagate the overridden linker language, if applicable
                get_target_property(_blt_link_lang ${dependency} INTERFACE_BLT_LINKER_LANGUAGE_OVERRIDE)
                # TODO: Do we need to worry about overwriting?  Should only ever be HIP or CUDA
                if(_blt_link_lang)
                    set_target_properties(${arg_NAME} PROPERTIES INTERFACE_BLT_LINKER_LANGUAGE_OVERRIDE ${_blt_link_lang})
                endif()
            endif()

            # Check if a separate device link is needed
            if(ENABLE_CUDA AND "${_dep_type}" STREQUAL "OBJECT_LIBRARY")
                get_target_property(_device_link ${dependency} CUDA_RESOLVE_DEVICE_SYMBOLS)
                if(_device_link AND CUDA_LINK_WITH_NVCC)
                    set(_dlink_obj "${dependency}_device_link${CMAKE_CUDA_OUTPUT_EXTENSION}")
                    # Make sure a target wasn't already added
                    get_source_file_property(_generated ${_dlink_obj} GENERATED)
                    if(NOT _generated)
                        # Convert string to list as it will be expanded
                        string(REPLACE " " ";" _cuda_flags ${CMAKE_CUDA_FLAGS})
                        add_custom_command(
                            OUTPUT ${_dlink_obj}
                            COMMAND ${CMAKE_CUDA_COMPILER} --device-link ${_cuda_flags} $<TARGET_OBJECTS:${dependency}> -o ${_dlink_obj}
                            DEPENDS $<TARGET_OBJECTS:${dependency}>
                            COMMAND_EXPAND_LISTS
                        )
                    endif()
                    target_sources(${arg_NAME} PRIVATE ${_dlink_obj})
                endif()
            endif()
        endif()
    endforeach()

endmacro(blt_setup_target)


##------------------------------------------------------------------------------
## blt_setup_cuda_target(NAME <name of target>
##                       SOURCES <list of sources>
##                       DEPENDS_ON <list of dependencies>
##                       LIBRARY_TYPE <STATIC, SHARED, OBJECT, or blank for executables>)
##------------------------------------------------------------------------------
macro(blt_setup_cuda_target)

    set(options)
    set(singleValueArgs NAME LIBRARY_TYPE)
    set(multiValueArgs SOURCES DEPENDS_ON)

    # Parse the arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                            "${multiValueArgs}" ${ARGN} )

    # Check arguments
    if ( NOT DEFINED arg_NAME )
        message( FATAL_ERROR "Must provide a NAME argument to the 'blt_setup_cuda_target' macro")
    endif()

    if ( NOT DEFINED arg_SOURCES )
        message( FATAL_ERROR "Must provide SOURCES to the 'blt_setup_cuda_target' macro")
    endif()

    # Determine if cuda or cuda_runtime are in DEPENDS_ON
    list(FIND arg_DEPENDS_ON "cuda" _cuda_index)
    list(FIND arg_DEPENDS_ON "blt::cuda" _cuda_index2)
    set(_depends_on_cuda FALSE)
    if(${_cuda_index} GREATER -1 OR ${_cuda_index2} GREATER -1)
        set(_depends_on_cuda TRUE)
    endif()
    list(FIND arg_DEPENDS_ON "cuda_runtime" _cuda_runtime_index)
    list(FIND arg_DEPENDS_ON "blt::cuda_runtime" _cuda_runtime_index2)
    set(_depends_on_cuda_runtime FALSE)
    if(${_cuda_runtime_index} GREATER -1 OR ${_cuda_runtime_index2} GREATER -1)
        set(_depends_on_cuda_runtime TRUE)
    endif()

    if (${_depends_on_cuda_runtime} OR ${_depends_on_cuda})
        if (CUDA_LINK_WITH_NVCC)
            set_target_properties( ${arg_NAME} PROPERTIES LINKER_LANGUAGE CUDA)
            # This will be propagated up to executable targets that depend on this
            # library, which will need the HIP linker
            set_target_properties( ${arg_NAME} PROPERTIES INTERFACE_BLT_LINKER_LANGUAGE_OVERRIDE CUDA)
        endif()
    endif()

    if (${_depends_on_cuda})
        # if cuda is in depends_on, flag each file's language as CUDA
        # instead of leaving it up to CMake to decide
        # Note: we don't do this when depending on just 'cuda_runtime'
        set(_cuda_sources)
        set(_non_cuda_sources)
        blt_split_source_list_by_language(SOURCES      ${arg_SOURCES}
                                          C_LIST       _cuda_sources
                                          Fortran_LIST _non_cuda_sources)

        set_source_files_properties( ${_cuda_sources} PROPERTIES
                                     LANGUAGE CUDA)

        if (DEFINED arg_LIBRARY_TYPE)
            if (${arg_LIBRARY_TYPE} STREQUAL "static")
                set_target_properties( ${arg_NAME} PROPERTIES
                                       CMAKE_CUDA_CREATE_STATIC_LIBRARY ON)
            else()
                set_target_properties( ${arg_NAME} PROPERTIES
                                       CMAKE_CUDA_CREATE_STATIC_LIBRARY OFF)
            endif()
        endif()

        # Replicate the behavior of CMAKE_CUDA_RESOLVE_DEVICE_SYMBOLS
        if(${CMAKE_VERSION} VERSION_LESS "3.16.0" AND CMAKE_CUDA_RESOLVE_DEVICE_SYMBOLS)
            set_target_properties( ${arg_NAME} PROPERTIES
                                   CUDA_RESOLVE_DEVICE_SYMBOLS ON)
        endif()
    endif()
endmacro(blt_setup_cuda_target)

##------------------------------------------------------------------------------
## blt_setup_hip_target(NAME <name of target>
##                       SOURCES <list of sources>
##                       DEPENDS_ON <list of dependencies>
##------------------------------------------------------------------------------
macro(blt_setup_hip_target)

    set(options)
    set(singleValueArgs NAME)
    set(multiValueArgs SOURCES DEPENDS_ON)

    # Parse the arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                            "${multiValueArgs}" ${ARGN} )

    # Check arguments
    if ( NOT DEFINED arg_NAME )
        message( FATAL_ERROR "Must provide a NAME argument to the 'blt_setup_hip_target' macro")
    endif()

    if ( NOT DEFINED arg_SOURCES )
        message( FATAL_ERROR "Must provide SOURCES to the 'blt_setup_hip_target' macro")
    endif()

    # Determine if hip is in DEPENDS_ON
    list(FIND arg_DEPENDS_ON "blt_hip" _hip_index)
    list(FIND arg_DEPENDS_ON "blt::hip" _hip_index2)
    set(_depends_on_hip FALSE)
    if(${_hip_index} GREATER -1 OR ${_hip_index2} GREATER -1)
        set(_depends_on_hip TRUE)
    endif()

    if (${_depends_on_hip})
        set(_hip_sources)
        set(_non_hip_sources)
        blt_split_source_list_by_language(SOURCES      ${arg_SOURCES}
                                          C_LIST       _non_hip_sources
                                          CXX_LIST     _hip_sources
                                          Fortran_LIST _non_hip_sources)

        set_source_files_properties( ${_hip_sources} PROPERTIES LANGUAGE HIP)

    endif()
endmacro(blt_setup_hip_target)


##-----------------------------------------------------------------------------
## blt_make_file_ext_regex( EXTENSIONS   [ext1 [ext2 ...]]
##                          OUTPUT_REGEX <regex variable name>)
##
## This function converts the list of extensions in EXTENSIONS and
## fills the variable, given in OUTPUT_REGEX, with a joined, with '|',
## regular expression. This regex should match any file name starting with
## a string and ending with any one of the extensions in EXTENSIONS.
## This also lower cases all extensions because we do not care about file casing.
## -----------------------------------------------------------------------------
macro(blt_make_file_ext_regex)

    set(options)
    set(singleValueArgs OUTPUT_REGEX)
    set(multiValueArgs EXTENSIONS)

    # Parse the arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                            "${multiValueArgs}" ${ARGN} )

    # Check arguments
    if ( NOT DEFINED arg_EXTENSIONS )
        message( FATAL_ERROR "Must provide a EXTENSIONS argument to the 'blt_make_file_ext_regex' macro" )
    endif()

    if ( NOT DEFINED arg_OUTPUT_REGEX )
        message( FATAL_ERROR "Must provide a OUTPUT_REGEX argument to the 'blt_make_file_ext_regex' macro" )
    endif()

    # Join with 'or', and escape periods
    list(JOIN arg_EXTENSIONS "|" ${arg_OUTPUT_REGEX})
    # Lower-case because we do case-insensitive checks
    string(TOLOWER "${BLT_C_FILE_REGEX}" BLT_C_FILE_REGEX)
    # Escape periods before adding 
    string(REPLACE "." "\\." ${arg_OUTPUT_REGEX} "${${arg_OUTPUT_REGEX}}")
    # Regex for by any set of characters followed by any of the given
    # file extensions at the end of the string
    set(${arg_OUTPUT_REGEX} "^.*(${${arg_OUTPUT_REGEX}})$")

endmacro(blt_make_file_ext_regex)


##------------------------------------------------------------------------------
## blt_split_source_list_by_language( SOURCES <sources>
##                                    C_LIST <list name>
##                                    CXX_LIST <list name>
##                                    Fortran_LIST <list name>
##                                    Python_LIST <list name>
##                                    CMAKE_LIST <list name>)
##
## Filters source list by file extension into C/C++, Fortran, Python, and
## CMake source lists based on BLT_C_FILE_EXTS, BLT_Fortran_FILE_EXTS,
## BLT_Python_FILE_EXTS and BLT_CMAKE_FILE_EXTS (global BLT variables).
## This filtering is case-insensitive. Files named "CMakeLists.txt" are
## also filtered here. Files with no extension or generator expressions
## that are not object libraries (of the form
## "$<TARGET_OBJECTS:nameofobjectlibrary>") will throw fatal errors.
## ------------------------------------------------------------------------------
macro(blt_split_source_list_by_language)

    set(options)
    set(singleValueArgs C_LIST CXX_LIST Fortran_LIST Python_LIST CMAKE_LIST)
    set(multiValueArgs SOURCES)

    # Parse the arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                            "${multiValueArgs}" ${ARGN} )

    # Check arguments
    if ( NOT DEFINED arg_SOURCES )
        message( FATAL_ERROR "Must provide a SOURCES argument to the 'blt_split_source_list_by_language' macro" )
    endif()

    # Convert extensions lists to regexes
    set(BLT_C_FILE_REGEX)
    blt_make_file_ext_regex(EXTENSIONS   ${BLT_C_FILE_EXTS}
                            OUTPUT_REGEX BLT_C_FILE_REGEX)
    set(BLT_CXX_FILE_REGEX)
    blt_make_file_ext_regex(EXTENSIONS   ${BLT_CXX_FILE_EXTS}
                            OUTPUT_REGEX BLT_CXX_FILE_REGEX)
    set(BLT_Fortran_FILE_REGEX)
    blt_make_file_ext_regex(EXTENSIONS   ${BLT_Fortran_FILE_EXTS}
                            OUTPUT_REGEX BLT_Fortran_FILE_REGEX)
    set(BLT_Python_FILE_REGEX)
    blt_make_file_ext_regex(EXTENSIONS   ${BLT_Python_FILE_EXTS}
                            OUTPUT_REGEX BLT_Python_FILE_REGEX)
    set(BLT_CMAKE_FILE_REGEX)
    blt_make_file_ext_regex(EXTENSIONS   ${BLT_CMAKE_FILE_EXTS}
                            OUTPUT_REGEX BLT_CMAKE_FILE_REGEX)

    # Generate source lists based on language
    foreach(_file ${arg_SOURCES})
        # Allow CMake object libraries but disallow generator expressions
        # in source lists due to this causing all sorts of bad side effects
        if("${_file}" MATCHES "^\\$<TARGET_OBJECTS:")
            continue()
        elseif("${_file}" MATCHES "^\\$<")
            message(FATAL_ERROR "blt_split_source_list_by_language macro does not support generator expressions because CMake does not provide a way to evaluate them. Given generator expression: ${_file}")
        endif()

        get_filename_component(_ext "${_file}" EXT)
        if("${_ext}" STREQUAL "")
            message(FATAL_ERROR "blt_split_source_list_by_language given source file with no extension: ${_file}")
        endif()

        get_filename_component(_name "${_file}" NAME)

        string(TOLOWER "${_file}" _lower_file)

        if("${_lower_file}" MATCHES "${BLT_C_FILE_REGEX}")
            if (DEFINED arg_C_LIST)
                list(APPEND ${arg_C_LIST} "${_file}")
            endif()
        elseif("${_lower_file}" MATCHES "${BLT_CXX_FILE_REGEX}")
            if (DEFINED arg_CXX_LIST)
                list(APPEND ${arg_CXX_LIST} "${_file}")
            # maintain backwards compatibilty by adding to C list if CXX list not set
            else()
                list(APPEND ${arg_C_LIST} "${_file}")
            endif()
        elseif("${_lower_file}" MATCHES "${BLT_Fortran_FILE_REGEX}")
            if (DEFINED arg_Fortran_LIST)
                list(APPEND ${arg_Fortran_LIST} "${_file}")
            endif()
        elseif("${_lower_file}" MATCHES "${BLT_Python_FILE_REGEX}")
            if (DEFINED arg_Python_LIST)
                list(APPEND ${arg_Python_LIST} "${_file}")
            endif()
        elseif("${_lower_file}" MATCHES "${BLT_CMAKE_REGEX}" OR "${_name}" STREQUAL "CMakeLists.txt")
            if (DEFINED arg_CMAKE_LIST)
                list(APPEND ${arg_CMAKE_LIST} "${_file}")
            endif()
        else()
            message(FATAL_ERROR "blt_split_source_list_by_language given source file with unknown file extension. Add the missing extension to the corresponding list (BLT_C_FILE_EXTS, BLT_Fortran_FILE_EXTS, BLT_Python_FILE_EXTS, or BLT_CMAKE_FILE_EXTS).\n Unknown file: ${_file}")
        endif()

    endforeach()

endmacro(blt_split_source_list_by_language)


##------------------------------------------------------------------------------
## blt_filter_list( TO <list_var> REGEX <string> OPERATION <string> )
##
## This macro provides the same functionality as cmake's list(FILTER )
## which is only available in cmake-3.6+.
##
## The TO argument (required) is the name of a list variable.
## The REGEX argument (required) is a string containing a regex.
## The OPERATION argument (required) is a string that defines the macro's operation.
## Supported values are "include" and "exclude"
##
## The filter is applied to the input list, which is modified in place.
##------------------------------------------------------------------------------
macro(blt_filter_list)

    set(options )
    set(singleValueArgs TO REGEX OPERATION)
    set(multiValueArgs )

    # Parse arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                            "${multiValueArgs}" ${ARGN} )

    # Check arguments
    if( NOT DEFINED arg_TO )
        message(FATAL_ERROR "blt_filter_list macro requires a TO <list> argument")
    endif()

    if( NOT DEFINED arg_REGEX )
        message(FATAL_ERROR "blt_filter_list macro requires a REGEX <string> argument")
    endif()

    # Ensure OPERATION argument is provided with value "include" or "exclude"
    set(_exclude)
    if( NOT DEFINED arg_OPERATION )
        message(FATAL_ERROR "blt_filter_list macro requires a OPERATION <string> argument")
    elseif(NOT arg_OPERATION MATCHES "^(include|exclude)$")
        message(FATAL_ERROR "blt_filter_list macro's OPERATION argument must be either 'include' or 'exclude'")
    else()
        if(${arg_OPERATION} MATCHES "exclude")
            set(_exclude TRUE)
        else()
            set(_exclude FALSE)
        endif()
    endif()

    # Filter the list
    set(_resultList)
    foreach(elem ${${arg_TO}})
        if(elem MATCHES ${arg_REGEX})
            if(NOT ${_exclude})
                list(APPEND _resultList ${elem})
            endif()
        else()
            if(${_exclude})
                list(APPEND _resultList ${elem})
            endif()
        endif()
    endforeach()

    # Copy result back to input list variable
    set(${arg_TO} ${_resultList})

    unset(_exclude)
    unset(_resultList)
endmacro(blt_filter_list)


##------------------------------------------------------------------------------
## blt_clean_target( TARGET <target name> )
##
## This macro removes duplicates in a small subset of target properties that are
## safe to do so.
##------------------------------------------------------------------------------
macro(blt_clean_target)

    set(options )
    set(singleValueArgs TARGET)
    set(multiValueArgs )

    # Parse arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                            "${multiValueArgs}" ${ARGN} )

    # Properties to remove duplicates from
    set(_dup_properties
        INCLUDE_DIRECTORIES
        INTERFACE_COMPILE_DEFINITIONS
        INTERFACE_INCLUDE_DIRECTORIES
        INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)

    foreach(_prop ${_dup_properties})
        get_target_property(_values ${arg_TARGET} ${_prop})
        if ( _values )
            list(REMOVE_DUPLICATES _values)
            set_property(TARGET ${arg_TARGET} PROPERTY ${_prop} ${_values})
        endif()
    endforeach()

endmacro(blt_clean_target)


##------------------------------------------------------------------------------
## blt_print_target_properties_private(TARGET <target>
##                                     PROPERTY_NAME_REGEX <regular expression>
##                                     PROPERTY_VALUE_REGEX <regular expression>)
##
## Prints target properties of one target
##------------------------------------------------------------------------------
macro(blt_print_target_properties_private)

    set(options)
    set(singleValuedArgs TARGET PROPERTY_NAME_REGEX PROPERTY_VALUE_REGEX)
    set(multiValuedArgs)

    ## parse the arguments to the macro
    cmake_parse_arguments(arg
         "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN})

    ## check if this is a valid cmake target or blt_registered target
    set(_is_cmake_target FALSE)
    set(_target_type_str "")
    if(TARGET ${arg_TARGET})
        set(_is_cmake_target TRUE)
        set(_target_type_str "CMake target")
    endif()

    set(_is_blt_registered_target FALSE)
    string(TOUPPER ${arg_TARGET} _target_upper)
    if(_BLT_${_target_upper}_IS_REGISTERED_LIBRARY)
        set(_is_blt_registered_target TRUE)
        if (_is_cmake_target)
            set(_target_type_str "${_target_type_str} and a ")
        endif()
        set(_target_type_str "${_target_type_str}BLT Registered target")
    endif()

    if (_is_cmake_target OR _is_blt_registered_target)
        message(STATUS "[${arg_TARGET} property] '${arg_TARGET}' is a ${_target_type_str}")
    endif()
    unset(_target_type_str)

    if(_is_cmake_target)
        ## Solution adapted from https://stackoverflow.com/q/32183975
        ## Create list of cmake properties
        set(_property_list)
        execute_process(COMMAND cmake --help-property-list OUTPUT_VARIABLE _property_list)
        string(REGEX REPLACE ";" "\\\\;" _property_list "${_property_list}")
        string(REGEX REPLACE "\n" ";" _property_list "${_property_list}")
        blt_filter_list(TO _property_list REGEX "^LOCATION$|^LOCATION_|_LOCATION$" OPERATION "exclude")
        blt_list_remove_duplicates(TO _property_list)   

        ## For interface targets, filter against whitelist of valid properties
        get_property(_target_type TARGET ${arg_TARGET} PROPERTY TYPE)
        if("${_target_type}" STREQUAL "INTERFACE_LIBRARY")
            blt_filter_list(TO _property_list
                            REGEX "^(INTERFACE_|IMPORTED_LIBNAME_|COMPATIBLE_INTERFACE_|MAP_IMPORTED_CONFIG_)|^(NAME|TYPE|EXPORT_NAME)$"
                            OPERATION "include")
        endif()

        ## Print all such properties that have been SET
        foreach (prop ${_property_list})
            string(REPLACE "<CONFIG>" "${CMAKE_BUILD_TYPE}" prop ${prop})
            get_property(_propval TARGET ${arg_TARGET} PROPERTY ${prop} SET)
            if ("${_propval}" AND "${prop}" MATCHES "${arg_PROPERTY_NAME_REGEX}")
                get_target_property(_propval ${arg_TARGET} ${prop})
                if ("${_propval}" MATCHES "${arg_PROPERTY_VALUE_REGEX}")
                    message (STATUS "[${arg_TARGET} property] ${prop}: ${_propval}")
                endif()
            endif()
        endforeach()
        unset(_property_list)
        unset(_propval)
    endif()

    ## Additionally, output variables generated via blt_register_target of the form "_BLT_<target>_*"
    if(_is_blt_registered_target)
        set(_target_prefix "_BLT_${_target_upper}_")

        ## Filter to get variables of the form _BLT_<target>_ and print
        get_cmake_property(_variable_names VARIABLES)
        foreach (prop ${_variable_names})
            if("${prop}" MATCHES "^${_target_prefix}" AND "${prop}" MATCHES "${arg_PROPERTY_NAME_REGEX}" AND "${${prop}}" MATCHES "${arg_PROPERTY_VALUE_REGEX}")
                message (STATUS "[${arg_TARGET} property] ${prop}: ${${prop}}")
            endif()
        endforeach()
        unset(_target_prefix)
        unset(_variable_names)
    endif()

    unset(_target_upper)
    unset(_is_blt_registered_target)
    unset(_is_cmake_target)
endmacro(blt_print_target_properties_private)
