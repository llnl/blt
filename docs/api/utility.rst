.. # Copyright (c) Lawrence Livermore National Security, LLC and other
.. # BLT Project Developers. See the top-level LICENSE file for details
.. # 
.. # SPDX-License-Identifier: (BSD-3-Clause)

Utility Macros
==============

.. _blt_assert_exists:

blt_assert_exists
~~~~~~~~~~~~~~~~~

.. code-block:: cmake

    blt_assert_exists(
      [DIRECTORIES <dir1> [<dir2> ...] ]
      [FILES <file1> [<file2> ...] ]
      [TARGETS <target1> [<target2> ...] ] )

Checks if the specified directory, file and/or cmake target exists and throws
an error message.

.. note::
   The behavior for checking if a given file or directory exists is well-defined
   only for absolute paths.

.. code-block:: cmake
   :caption: **Example**
   :linenos:

   ## check if the directory 'blt' exists in the project
   blt_assert_exists( DIRECTORIES ${PROJECT_SOURCE_DIR}/cmake/blt )

   ## check if the file 'SetupBLT.cmake' file exists
   blt_assert_exists( FILES ${PROJECT_SOURCE_DIR}/cmake/blt/SetupBLT.cmake )

   ## checks can also be bundled in one call
   blt_assert_exists( DIRECTORIES ${PROJECT_SOURCE_DIR}/cmake/blt
                      FILES ${PROJECT_SOURCE_DIR}/cmake/blt/SetupBLT.cmake )

   ## check if the CMake targets `foo` and `bar` exist
   blt_assert_exists( TARGETS foo bar )


.. _blt_append_custom_compiler_flag:

blt_append_custom_compiler_flag
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

    blt_append_custom_compiler_flag( 
                       FLAGS_VAR  flagsVar       (required)
                       DEFAULT    defaultFlag    (optional)
                       GNU        gnuFlag        (optional)
                       CLANG      clangFlag      (optional)
                       INTEL      intelFlag      (optional)
                       INTELLLVM  intelLLVMFlag  (optional)
                       XL         xlFlag         (optional)
                       MSVC       msvcFlag       (optional)
                       MSVC_INTEL msvcIntelFlag  (optional)
                       PGI        pgiFlag        (optional)
                       CRAY       crayFlag       (optional))

Appends compiler-specific flags to a given variable of flags

If a custom flag is given for the current compiler, we use that.
Otherwise, we will use the ``DEFAULT`` flag (if present).

If ``ENABLE_FORTRAN`` is ``ON``, any flagsVar with ``fortran`` (any capitalization)
in its name will pick the compiler family (GNU,CLANG, INTEL, etc) based on
the fortran compiler family type. This allows mixing C and Fortran compiler
families, e.g. using Intel fortran compilers with clang C compilers. 

When using the Intel toolchain within Visual Studio, we use the 
``MSVC_INTEL`` flag, when provided, with a fallback to the ``MSVC`` flag.


.. blt_check_code_compiles:

blt_check_code_compiles
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

     blt_check_code_compiles(CODE_COMPILES  <variable>
                             VERBOSE_OUTPUT <ON|OFF (default OFF)>
                             SOURCE_STRING  <quoted C++ program>)

This macro checks if a snippet of C++ code compiles.

CODE_COMPILES
  The boolean variable that will be filled with the compilation result.

VERBOSE_OUTPUT
  Optional parameter to output debug information (Default: OFF)

SOURCE_STRING
  The source snippet to compile.

``SOURCE_STRING`` must be a valid C++ program with a main() function and
must be passed in as a quoted string variable. Otherwise, CMake will convert
the string into a list and lose the semicolons.  You can use any CMake method
of sending a string, but we recommend the
`bracket argument method <https://cmake.org/cmake/help/latest/manual/cmake-language.7.html#bracket-argument>`_
shown below so you do not have to escape your quotes:

.. code-block:: cmake

    blt_check_code_compiles(CODE_COMPILES  hello_world_compiled
                            SOURCE_STRING
    [=[
    #include <iostream>

    int main(int, char**)
    {

        std::cout << "Hello World!" << std::endl;

        return 0;
    }
    ]=])




.. _blt_find_libraries:

blt_find_libraries
~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

    blt_find_libraries( FOUND_LIBS <FOUND_LIBS variable name>
                        NAMES      [libname1 [libname2 ...]]
                        REQUIRED   [TRUE (default) | FALSE ]
                        PATHS      [path1 [path2 ...]])

This command is used to find a list of libraries.

If the libraries are found the results are appended to the given ``FOUND_LIBS`` variable name.
``NAMES`` lists the names of the libraries that will be searched for in the given ``PATHS``.

If ``REQUIRED`` is set to ``TRUE``, BLT will produce an error message if any of the
given libraries are not found.  The default value is ``TRUE``.

``PATH`` lists the paths in which to search for ``NAMES``. No system paths will be searched.


.. _blt_list_append:

blt_list_append
~~~~~~~~~~~~~~~

.. code-block:: cmake

    blt_list_append(TO       <list>
                    ELEMENTS [<element>...]
                    IF       <bool>)

Appends elements to a list if the specified bool evaluates to true.

This macro is essentially a wrapper around CMake's ``list(APPEND ...)``
command which allows inlining a conditional check within the same call
for clarity and convenience.

This macro requires specifying:

    * The target list to append to by passing ``TO <list>``
    * A condition to check by passing ``IF <bool>``
    * The list of elements to append by passing ``ELEMENTS [<element>...]``

.. note::
  The argument passed to the ``IF`` option has to be a single boolean value
  and cannot be a boolean expression since CMake cannot evaluate those inline.

.. code-block:: cmake
    :caption: **Example**
    :linenos:

    set(mylist A B)
    
    set(ENABLE_C TRUE)
    blt_list_append( TO mylist ELEMENTS C IF ${ENABLE_C} ) # Appends 'C'

    set(ENABLE_D TRUE)
    blt_list_append( TO mylist ELEMENTS D IF ENABLE_D ) # Appends 'D'

    set(ENABLE_E FALSE)
    blt_list_append( TO mylist ELEMENTS E IF ENABLE_E ) # Does not append 'E'

    unset(_undefined)
    blt_list_append( TO mylist ELEMENTS F IF _undefined ) # Does not append 'F'


.. _blt_list_remove_duplicates:

blt_list_remove_duplicates
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

    blt_list_remove_duplicates(TO <list>)

Removes duplicate elements from the given ``TO`` list.

This macro is essentially a wrapper around CMake's ``list(REMOVE_DUPLICATES ...)``
command but doesn't throw an error if the list is empty or not defined.

.. code-block:: cmake
    :caption: **Example**
    :linenos:

    set(mylist A B A)
    blt_list_remove_duplicates( TO mylist )

.. _blt_find_target_dependencies:

blt_find_target_dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

    set(_target_list "")
    blt_find_target_dependencies(TARGET <target> TLIST _target_list)

Recursively adds all link libraries and interface link libraries of the given
target to the given list. Handles CMake targets and BLT registered libraries.

.. _blt_convert_to_system_includes:

blt_convert_to_system_includes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

    blt_convert_to_system_includes(TARGET   <target>
                                   TARGETS  [<target>...]
                                   CHILDREN [TRUE | FALSE (default)]
                                   [QUIET])

Converts existing interface includes to system interface includes.
Warns if a target does not exist unless ``QUIET`` is specified.
Recurses through link libraries and interface link libraries if
``CHILDREN TRUE`` is specified.

.. note::
  The argument ``TARGET`` will be deprecated in the near future. Until then,
  if both ``TARGET`` and ``TARGETS`` is given, all given target include
  directories will be converted.

.. code-block:: cmake
   :caption: **Example**
   :linenos:

   blt_convert_to_system_includes(TARGETS foo)

