# Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)

# Macros used to create targets for third-party libraries in downstream targets.

##------------------------------------------------------------------------------
## blt_assert_exists( [DIRECTORIES [<dir1> <dir2> ...] ]
##                    [TARGETS [<target1> <target2> ...] ]
##                    [FILES <file1> <file2> ...] )
##
## Throws a FATAL_ERROR message if any of the specified directories, files, or 
## targets do not exist.
##------------------------------------------------------------------------------
macro(blt_assert_exists)

    set(options)
    set(singleValueArgs)
    set(multiValueArgs DIRECTORIES TARGETS FILES)

    # parse macro arguments
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    if (DEFINED arg_DIRECTORIES)
        foreach (_dir ${arg_DIRECTORIES})
            if (NOT IS_DIRECTORY ${_dir})
                message(FATAL_ERROR "directory [${_dir}] does not exist!")
            endif()
        endforeach()
    endif()

    if (DEFINED arg_FILES)
        foreach (_file ${arg_FILES})
            if (NOT EXISTS ${_file})
                message(FATAL_ERROR "file [${_file}] does not exist!")
            endif()
        endforeach()
    endif()

    if (DEFINED arg_TARGETS)
        foreach (_target ${arg_TARGETS})
            if (NOT TARGET ${_target})
                message(FATAL_ERROR "target [${_target}] does not exist!")
            endif()
        endforeach()
    endif()

endmacro(blt_assert_exists)


##------------------------------------------------------------------------------
## blt_inherit_target_info( TO       <target>
##                          FROM     <target>
##                          OBJECT   [TRUE|FALSE])
##
##  The purpose of this macro is if you want to grab all the inheritable info
##  from the FROM target but don't want to make the TO target depend on it.
##  Which is useful if you don't want to export the FROM target.
##
##  The OBJECT parameter is because object libraries can only inherit certain
##  properties.
##
##  This inherits the following properties:
##    INTERFACE_COMPILE_DEFINITIONS
##    INTERFACE_INCLUDE_DIRECTORIES
##    INTERFACE_LINK_DIRECTORIES
##    INTERFACE_LINK_LIBRARIES
##    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
##------------------------------------------------------------------------------
macro(blt_inherit_target_info)
    set(options)
    set(singleValueArgs TO FROM OBJECT)
    set(multiValueArgs)

    # Parse the arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                        "${multiValueArgs}" ${ARGN} )

    # Check arguments
    if ( NOT DEFINED arg_TO )
        message( FATAL_ERROR "Must provide a TO argument to the 'blt_inherit_target' macro" )
    endif()

    if ( NOT DEFINED arg_FROM )
        message( FATAL_ERROR "Must provide a FROM argument to the 'blt_inherit_target' macro" )
    endif()

    blt_determine_scope(TARGET ${arg_TO} OUT _scope)

    get_target_property(_interface_system_includes
                        ${arg_FROM} INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)
    if ( _interface_system_includes )
        target_include_directories(${arg_TO} SYSTEM ${_scope} ${_interface_system_includes})
    endif()

    get_target_property(_interface_includes
                        ${arg_FROM} INTERFACE_INCLUDE_DIRECTORIES)
    if ( _interface_includes )
        target_include_directories(${arg_TO} ${_scope} ${_interface_includes})
    endif()

    get_target_property(_interface_defines
                        ${arg_FROM} INTERFACE_COMPILE_DEFINITIONS)
    if ( _interface_defines )
        target_compile_definitions( ${arg_TO} ${_scope} ${_interface_defines})
    endif()

    if( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.13.0" )
        get_target_property(_interface_link_options
                            ${arg_FROM} INTERFACE_LINK_OPTIONS)
        if ( _interface_link_options )
            target_link_options( ${arg_TO} ${_scope} ${_interface_link_options})
        endif()
    endif()

    get_target_property(_interface_compile_options
                        ${arg_FROM} INTERFACE_COMPILE_OPTIONS)
    if ( _interface_compile_options )
        target_compile_options( ${arg_TO} ${_scope} ${_interface_compile_options})
    endif()

    if ( NOT arg_OBJECT )
        get_target_property(_interface_link_directories
                            ${arg_FROM} INTERFACE_LINK_DIRECTORIES)
        if ( _interface_link_directories )
            target_link_directories( ${arg_TO} ${_scope} ${_interface_link_directories})
        endif()

        get_target_property(_interface_link_libraries
                            ${arg_FROM} INTERFACE_LINK_LIBRARIES)
        if ( _interface_link_libraries )
            target_link_libraries( ${arg_TO} ${_scope} ${_interface_link_libraries})
        endif()
    endif()

endmacro(blt_inherit_target_info)

##------------------------------------------------------------------------------
## blt_list_append( TO <list> ELEMENTS [ <element>...] IF <bool> )
##
## Appends elements to a list if the specified bool evaluates to true.
##------------------------------------------------------------------------------
macro(blt_list_append)

    set(options)
    set(singleValueArgs TO IF)
    set(multiValueArgs ELEMENTS )

    # parse macro arguments
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

     # Sanity checks
    if( NOT DEFINED arg_TO )
        message(FATAL_ERROR "blt_list_append() requires a TO <list> argument")
    endif()

    # determine if we should add the elements to the list
    set(_shouldAdd FALSE )
    set(_listVar "${ARGN}")         # convert macro arguments to list variable
    if("IF" IN_LIST _listVar)
        set(_shouldAdd ${arg_IF})   # use IF condition, when present
    else()
        set(_shouldAdd TRUE)        # otherwise, always add the elements
    endif()

    # append if
    if ( ${_shouldAdd} )
        # check that ELEMENTS parameter is defined/non-empty before appending
        if ( NOT DEFINED arg_ELEMENTS )
            message(FATAL_ERROR "blt_list_append() requires ELEMENTS to be specified and non-empty" )
        endif()

        list( APPEND ${arg_TO} ${arg_ELEMENTS} )
    endif()

    unset(_shouldAdd)
    unset(_listVar)

endmacro(blt_list_append)


##------------------------------------------------------------------------------
## blt_list_remove_duplicates( TO <list> )
##
## Removes duplicate elements from the given TO list.
##------------------------------------------------------------------------------
macro(blt_list_remove_duplicates)

    set(options)
    set(singleValueArgs TO )
    set(multiValueArgs )

    # parse macro arguments
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    # Sanity checks
    if( NOT DEFINED arg_TO )
        message(FATAL_ERROR "blt_list_append() requires a TO <list> argument")
    endif()

    if ( ${arg_TO} )
        list(REMOVE_DUPLICATES ${arg_TO} )
    endif()

endmacro(blt_list_remove_duplicates)


##------------------------------------------------------------------------------
## blt_add_target_link_flags (TO    <target>
##                            SCOPE <PUBLIC (Default)| INTERFACE | PRIVATE>
##                            FLAGS [FOO [BAR ...]])
##
## Adds linker flags to a target by appending to the target's existing flags.
##------------------------------------------------------------------------------
macro(blt_add_target_link_flags)

    set(options)
    set(singleValuedArgs TO SCOPE)
    set(multiValuedArgs FLAGS)

    ## parse the arguments to the macro
    cmake_parse_arguments(arg
         "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN} )

    set(_flags ${arg_FLAGS})
    # Convert rpath flag if linking with CUDA
    if (CUDA_LINK_WITH_NVCC)
        string(REPLACE "-Wl,-rpath," "-Xlinker -rpath -Xlinker "
                       _flags "${_flags}")
    endif()

    # Only add the flag if it is not empty
    if(NOT "${arg_FLAGS}" STREQUAL "")
        if( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.13.0" )
            # In CMake 3.13+, LINK_FLAGS was converted to LINK_OPTIONS.
            # This now supports generator expressions and scoping but expects a list
            # not a string
            blt_determine_scope(TARGET ${arg_TO} SCOPE "${arg_SCOPE}" OUT _scope)

            # Note: "SHELL:"" causes the flags to be not de-duplicated and parsed with
            # separate_arguments
            if(NOT "${arg_FLAGS}" MATCHES SHELL:)
                target_link_options(${arg_TO} ${_scope} SHELL:${arg_FLAGS})
            else()
                target_link_options(${arg_TO} ${_scope} ${arg_FLAGS})
            endif()
        else()
            # In CMake <= 3.12, there is no target_link_flags or target_link_options command
            get_target_property(_target_type ${arg_TO} TYPE)
            if ("${_target_type}" STREQUAL "INTERFACE_LIBRARY")
                # If it's an interface library, we add the flag via link_libraries
                if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.11.0")
                    target_link_libraries(${arg_TO} INTERFACE ${_flags})
                else()
                    set_property(TARGET ${arg_NAME} APPEND PROPERTY
                                 INTERFACE_LINK_LIBRARIES ${_flags})
                endif()
            else()
                get_target_property(_link_flags ${arg_TO} LINK_FLAGS)
                # Append to existing flags
                if(NOT _link_flags)
                    set(_link_flags "")
                endif()
                set(_link_flags "${_flags} ${_link_flags}")

                # Convert from a CMake ;-list to a string
                string (REPLACE ";" " " _link_flags_str "${_link_flags}")

                set_target_properties(${arg_TO}
                                      PROPERTIES LINK_FLAGS "${_link_flags_str}")
            endif()

        endif()
    endif()

    unset(_flags)
    unset(_link_flags)
    unset(_link_flags_str)
    unset(_scope)

endmacro(blt_add_target_link_flags)


##-----------------------------------------------------------------------------
## blt_determine_scope(TARGET <target>
##                     SCOPE  <PUBLIC (Default)| INTERFACE | PRIVATE>
##                     OUT    <out variable name>)
##
## Returns the normalized scope string for a given SCOPE and TARGET to be used
## in BLT macros.
##
## TARGET - Name of CMake Target that the property is being added to
##          Note: the only real purpose of this parameter is to make sure we aren't
##                adding returning other than INTERFACE for Interface Libraries
## SCOPE  - case-insensitive scope string, defaults to PUBLIC
## OUT    - variable that is filled with the uppercased scope
##
##-----------------------------------------------------------------------------
macro(blt_determine_scope)

    set(options)
    set(singleValueArgs TARGET SCOPE OUT)
    set(multiValueArgs )

    # Parse the arguments
    cmake_parse_arguments(arg "${options}" "${singleValueArgs}"
                        "${multiValueArgs}" ${ARGN} )

    # Convert to upper case and strip white space
    string(TOUPPER "${arg_SCOPE}" _uppercaseScope)
    string(STRIP "${_uppercaseScope}" _uppercaseScope )

    if("${_uppercaseScope}" STREQUAL "")
        # Default to public
        set(_uppercaseScope PUBLIC)
    elseif(NOT ("${_uppercaseScope}" STREQUAL "PUBLIC" OR
                "${_uppercaseScope}" STREQUAL "INTERFACE" OR
                "${_uppercaseScope}" STREQUAL "PRIVATE"))
        message(FATAL_ERROR "Given SCOPE (${arg_SCOPE}) is not valid, valid options are:"
                            "PUBLIC, INTERFACE, or PRIVATE")
    endif()

    if(TARGET ${arg_TARGET})
        get_property(_targetType TARGET ${arg_TARGET} PROPERTY TYPE)
        if(${_targetType} STREQUAL "INTERFACE_LIBRARY")
            # Interface targets can only set INTERFACE
            if("${_uppercaseScope}" STREQUAL "PUBLIC" OR
               "${_uppercaseScope}" STREQUAL "INTERFACE")
                set(${arg_OUT} INTERFACE)
            else()
                message(FATAL_ERROR "Cannot set PRIVATE scope to Interface Library."
                                    "Change to Scope to INTERFACE.")
            endif()
        else()
            set(${arg_OUT} ${_uppercaseScope})
        endif()
    else()
        set(${arg_OUT} ${_uppercaseScope})
    endif()

    unset(_targetType)
    unset(_uppercaseScope)

endmacro(blt_determine_scope)


##------------------------------------------------------------------------------
## blt_add_target_definitions(TO     <target>
##                            SCOPE  <PUBLIC (Default)| INTERFACE | PRIVATE>
##                            TARGET_DEFINITIONS [FOO [BAR ...]])
##
## Adds pre-processor definitions to the given target.
##------------------------------------------------------------------------------
macro(blt_add_target_definitions)

    set(options)
    set(singleValueArgs TO SCOPE)
    set(multiValueArgs TARGET_DEFINITIONS)

    # Parse the arguments to the macro
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN})

    # Sanity checks
    if(NOT TARGET ${arg_TO})
        message(FATAL_ERROR "Target ${arg_TO} passed to blt_add_target_definitions is not a valid cmake target")    
    endif()

    blt_determine_scope(TARGET ${arg_TO} SCOPE "${arg_SCOPE}" OUT _scope)

    # Only add the flag if it is not empty
    string(STRIP "${arg_TARGET_DEFINITIONS}" _strippedDefs)
    if(NOT "${_strippedDefs}" STREQUAL "")
        target_compile_definitions(${arg_TO} ${_scope} ${_strippedDefs})
    endif()

    unset(_scope)
    unset(_strippedDefs)

endmacro(blt_add_target_definitions)


##------------------------------------------------------------------------------
## blt_add_target_compile_flags(TO    <target>
##                              SCOPE  <PUBLIC (Default)| INTERFACE | PRIVATE>
##                              FLAGS [FOO [BAR ...]])
##
## Adds compiler flags to a target (library, executable or interface) by 
## appending to the target's existing flags.
##------------------------------------------------------------------------------
macro(blt_add_target_compile_flags)

    set(options)
    set(singleValuedArgs TO SCOPE)
    set(multiValuedArgs FLAGS)

    # Parse the arguments to the macro
    cmake_parse_arguments(arg
         "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN} )

    # Sanity checks
    if(NOT TARGET ${arg_TO})
        message(FATAL_ERROR "Target ${arg_TO} passed to blt_add_target_compile_flags is not a valid cmake target")    
    endif()

    blt_determine_scope(TARGET ${arg_TO} SCOPE "${arg_SCOPE}" OUT _scope)

    # Only add the flag if it is not empty
    string(STRIP "${arg_FLAGS}" _strippedFlags)
    if(NOT "${_strippedFlags}" STREQUAL "")
        get_target_property(_target_type ${arg_TO} TYPE)
        if (("${_target_type}" STREQUAL "INTERFACE_LIBRARY") AND (${CMAKE_VERSION} VERSION_LESS "3.11.0"))
            set_property(TARGET ${arg_NAME} APPEND PROPERTY
                         INTERFACE_COMPILE_OPTIONS ${_strippedFlags})
        else()
            target_compile_options(${arg_TO} ${_scope} ${_strippedFlags})
        endif()
    endif()

    unset(_strippedFlags)
    unset(_scope)

endmacro(blt_add_target_compile_flags)


##------------------------------------------------------------------------------
## blt_find_target_dependencies(TARGET <target> TLIST <list name>)
##
## Store all target's dependencies (link libraries and interface link libraries)
## recursively in the variable name TLIST holds.
##------------------------------------------------------------------------------
macro(blt_find_target_dependencies)
    set(options)
    set(singleValuedArgs TARGET TLIST)
    set(multiValuedArgs)

    # parse the arguments to the macro
    cmake_parse_arguments(arg
         "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN})

    # check for required arguments
    if(NOT DEFINED arg_TARGET)
        message(FATAL_ERROR "TARGET is a required parameter for the blt_find_target_dependencies macro")
    endif()

    if(NOT DEFINED arg_TLIST OR NOT DEFINED ${arg_TLIST})
        message(FATAL_ERROR "TLIST is a required parameter for the blt_find_target_dependencies macro")
    endif()

    set(_depends_on "")

    # Get dependencies if BLT registered library
    string(TOUPPER ${arg_TARGET} _target_upper)
    if(_BLT_${_target_upper}_IS_REGISTERED_LIBRARY)
        list(APPEND _depends_on "${_BLT_${_target_upper}_DEPENDS_ON}")
    endif()
    unset(_target_upper)

    # Get dependencies if CMake target
    if(TARGET ${arg_TARGET})
        get_property(_target_type TARGET ${arg_TARGET} PROPERTY TYPE)
        if(NOT "${_target_type}" STREQUAL "INTERFACE_LIBRARY")
            get_target_property(_propval ${arg_TARGET} LINK_LIBRARIES)
            if(_propval)
                list(APPEND _depends_on ${_propval})
            endif()
        endif()

        # get interface link libraries
        get_target_property(_propval ${arg_TARGET} INTERFACE_LINK_LIBRARIES)
        if (_propval)
            list(APPEND _depends_on ${_propval})
        endif()
    endif()

    blt_list_remove_duplicates(TO _depends_on)
    foreach(t ${_depends_on})
        if (NOT "${t}" IN_LIST ${arg_TLIST})
            list(APPEND ${arg_TLIST} ${t})
            blt_find_target_dependencies(TARGET ${t} TLIST ${arg_TLIST})
        endif()
    endforeach()

    unset(_depends_on)
endmacro(blt_find_target_dependencies)


##------------------------------------------------------------------------------
## blt_convert_to_system_includes(TARGET   <target>
##                                TARGETS  [<target>...]
##                                CHILDREN [TRUE|FALSE]
##                                [QUIET])
##
## Converts existing interface includes to system interface includes.
##
## Note: The argument ``TARGET`` will be deprecated in the near future. Until then,
## if both ``TARGET`` and ``TARGETS`` is given, all given target include
## directories will be converted.
##
##------------------------------------------------------------------------------
function(blt_convert_to_system_includes)
    set(options QUIET)
    set(singleValuedArgs CHILDREN TARGET)
    set(multiValuedArgs TARGETS)

    ## parse the arguments to the macro
    cmake_parse_arguments(arg
        "${options}" "${singleValuedArgs}" "${multiValuedArgs}" ${ARGN})

    if(NOT DEFINED arg_TARGET AND NOT DEFINED arg_TARGETS)
        message(FATAL_ERROR "Neither required TARGET or TARGETS parameters for the blt_convert_to_system_includes macro were provided.")
    endif()

    if(DEFINED arg_TARGET)
        list(APPEND arg_TARGETS ${arg_TARGET})
    endif()

    if(NOT DEFINED arg_TARGETS)
        message(FATAL_ERROR "TARGETS is a required parameter for the blt_convert_to_system_includes macro.")
    endif()

    if(NOT DEFINED arg_CHILDREN)
        set(arg_CHILDREN FALSE)
    endif()

    # PGI does not support -isystem
    if(NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "PGI")
        set(_target_list "")

        foreach(_target ${arg_TARGETS})
            string(TOUPPER ${_target} _target_upper)

            if(TARGET ${_target} OR _BLT_${_target_upper}_IS_REGISTERED_LIBRARY)
                if(${arg_CHILDREN})
                    blt_find_target_dependencies(TARGET ${_target} TLIST _target_list)
                endif()

                list(APPEND _target_list ${_target})
            elseif(NOT ${arg_QUIET})
                message(WARNING "${_target} does not exist!")
            endif()

            unset(_target_upper)
        endforeach()

        blt_list_remove_duplicates(TO _target_list)

        foreach(_target ${_target_list})
            if(TARGET ${_target})
                # Handle CMake target
                get_target_property(_interface_include_dirs
                                    ${_target}
                                    INTERFACE_INCLUDE_DIRECTORIES)

                # Don't update properties if the target had no interface include directories
                if(_interface_include_dirs)
                    # Clear previous value in INTERFACE_INCLUDE_DIRECTORIES
                    # so it is not doubled by target_include_directories
                    set_target_properties(${_target}
                                          PROPERTIES
                                          INTERFACE_INCLUDE_DIRECTORIES "")

                    target_include_directories(${_target}
                                               SYSTEM
                                               INTERFACE
                                               ${_interface_include_dirs})
                endif()

                unset(_interface_include_dirs)
            else()
                string(TOUPPER ${_target} _target_upper)

                if(_BLT_${_target_upper}_IS_REGISTERED_LIBRARY)
                    # Handle BLT registered target
                    set(_BLT_${_target_upper}_TREAT_INCLUDES_AS_SYSTEM TRUE)
                endif()

                unset(_target_upper)
            endif()
        endforeach()

        unset(_target_list)
     elseif(NOT ${arg_QUIET})
        message(WARNING "PGI compiler does not support system includes")
     endif()
endfunction(blt_convert_to_system_includes)


##------------------------------------------------------------------------------
## blt_patch_target( NAME <targetname>
##                   DEPENDS_ON [dep1 [dep2 ...]]
##                   INCLUDES [include1 [include2 ...]]
##                   LIBRARIES [lib1 [lib2 ...]]
##                   TREAT_INCLUDES_AS_SYSTEM [ON|OFF]
##                   FORTRAN_MODULES [ path1 [ path2 ..]]
##                   COMPILE_FLAGS [ flag1 [ flag2 ..]]
##                   LINK_FLAGS [ flag1 [ flag2 ..]]
##                   DEFINES [def1 [def2 ...]] )
##
## Modifies an existing CMake target - sets PUBLIC visibility except for INTERFACE
## libraries, which use INTERFACE visibility
##------------------------------------------------------------------------------
macro(blt_patch_target)
    set(singleValueArgs NAME TREAT_INCLUDES_AS_SYSTEM)
    set(multiValueArgs INCLUDES 
                       DEPENDS_ON
                       LIBRARIES
                       FORTRAN_MODULES
                       COMPILE_FLAGS
                       LINK_FLAGS
                       DEFINES )

    ## parse the arguments
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    # Input checks
    if( "${arg_NAME}" STREQUAL "" )
        message(FATAL_ERROR "blt_patch_target() must be called with argument NAME <name>")
    endif()

    if (NOT TARGET ${arg_NAME})
        message(FATAL_ERROR "blt_patch_target() NAME argument must be a native CMake target")
    endif()

    # Default to public scope, unless it's an interface library
    set(_scope PUBLIC)
    get_target_property(_target_type ${arg_NAME} TYPE)
    if("${_target_type}" STREQUAL "INTERFACE_LIBRARY")
        set(_scope INTERFACE)
    endif()

    # Interface libraries were heavily restricted pre-3.11
    set(_standard_lib_interface FALSE)
    if((${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.11.0") OR (NOT "${_target_type}" STREQUAL "INTERFACE_LIBRARY"))
        set(_standard_lib_interface TRUE)
    endif()

    # LIBRARIES and DEPENDS_ON are kept separate in case different logic is needed for
    # the library itself versus its dependencies
    set(_libs_to_link "")
    if( arg_LIBRARIES )
        list(APPEND _libs_to_link ${arg_LIBRARIES})
    endif()

    # TODO: This won't expand BLT-registered libraries
    if( arg_DEPENDS_ON )
        list(APPEND _libs_to_link ${arg_DEPENDS_ON})
    endif()

    if(_standard_lib_interface)
        target_link_libraries(${arg_NAME} ${_scope} ${_libs_to_link})
    else()
        set_property(TARGET ${arg_NAME} APPEND PROPERTY
                     INTERFACE_LINK_LIBRARIES ${_libs_to_link})
    endif()
        
    if( arg_INCLUDES )
        if(_standard_lib_interface)
            target_include_directories(${arg_NAME} ${_scope} ${arg_INCLUDES})
        else()
            # Interface include directories need to be set manually
            set_property(TARGET ${arg_NAME} APPEND PROPERTY 
                         INTERFACE_INCLUDE_DIRECTORIES ${arg_INCLUDES})
        endif()
    endif()

    if(${arg_TREAT_INCLUDES_AS_SYSTEM})
        blt_convert_to_system_includes(TARGETS ${arg_NAME})
    endif()

    # FIXME: Is this all that's needed?
    if( arg_FORTRAN_MODULES )
        target_include_directories(${arg_NAME} ${_scope} ${arg_FORTRAN_MODULES})
    endif()

    if( arg_COMPILE_FLAGS )
        blt_add_target_compile_flags(TO ${arg_NAME} 
                                     SCOPE ${_scope}
                                     FLAGS ${arg_COMPILE_FLAGS})
    endif()
    
    if( arg_LINK_FLAGS )
        blt_add_target_link_flags(TO ${arg_NAME} 
                                  SCOPE ${_scope}
                                  FLAGS ${arg_LINK_FLAGS})
    endif()
    
    if( arg_DEFINES )
        blt_add_target_definitions(TO ${arg_NAME} 
                                   SCOPE ${_scope}
                                   TARGET_DEFINITIONS ${arg_DEFINES})
    endif()

endmacro(blt_patch_target)


##------------------------------------------------------------------------------
## blt_import_library( NAME <libname>
##                     LIBRARIES [lib1 [lib2 ...]]
##                     DEPENDS_ON [dep1 [dep2 ...]]
##                     INCLUDES [include1 [include2 ...]]
##                     TREAT_INCLUDES_AS_SYSTEM [ON|OFF]
##                     FORTRAN_MODULES [ path1 [ path2 ..]]
##                     COMPILE_FLAGS [ flag1 [ flag2 ..]]
##                     LINK_FLAGS [ flag1 [ flag2 ..]]
##                     DEFINES [def1 [def2 ...]] 
##                     GLOBAL [ON|OFF]
##                     EXPORTABLE [ON|OFF])
##
## Imports a library as a CMake target
##------------------------------------------------------------------------------
macro(blt_import_library)
    set(singleValueArgs NAME TREAT_INCLUDES_AS_SYSTEM GLOBAL EXPORTABLE)
    set(multiValueArgs LIBRARIES
                       INCLUDES 
                       DEPENDS_ON
                       FORTRAN_MODULES
                       COMPILE_FLAGS
                       LINK_FLAGS
                       DEFINES )

    ## parse the arguments
    cmake_parse_arguments(arg
        "${options}" "${singleValueArgs}" "${multiValueArgs}" ${ARGN} )

    # Input checks
    if( "${arg_NAME}" STREQUAL "" )
        message(FATAL_ERROR "blt_import_library() must be called with argument NAME <name>")
    endif()

    if(${arg_EXPORTABLE})
        if(${arg_GLOBAL})
            message(FATAL_ERROR "blt_import_library: EXPORTABLE targets cannot be GLOBAL")
        endif()
        add_library(${arg_NAME} INTERFACE)
    elseif(${arg_GLOBAL})
        add_library(${arg_NAME} INTERFACE IMPORTED GLOBAL)
    else()
        add_library(${arg_NAME} INTERFACE IMPORTED)
    endif()

    blt_patch_target(
        NAME       ${arg_NAME}
        LIBRARIES  ${arg_LIBRARIES}
        DEPENDS_ON ${arg_DEPENDS_ON}
        INCLUDES   ${arg_INCLUDES}
        DEFINES    ${arg_DEFINES}
        TREAT_INCLUDES_AS_SYSTEM ${arg_TREAT_INCLUDES_AS_SYSTEM}
        FORTRAN_MODULES ${arg_FORTRAN_MODULES}
        COMPILE_FLAGS ${arg_COMPILE_FLAGS}
        LINK_FLAGS ${arg_LINK_FLAGS}
        DEFINES ${arg_DEFINES}
    )
endmacro(blt_import_library)
