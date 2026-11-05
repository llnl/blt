.. # Copyright (c) Lawrence Livermore National Security, LLC and other
.. # BLT Project Developers. See the top-level LICENSE file for details
.. #
.. # SPDX-License-Identifier: (BSD-3-Clause)

Documentation Macros
===================

.. _blt_add_doxygen_target:

blt_add_doxygen_target
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

    blt_add_doxygen_target(TARGET doxygen_target_name)

Creates a build target for invoking Doxygen to generate docs. Expects to
find a ``Doxyfile.in`` in the directory the macro is called in.

This macro sets up the doxygen paths so that the doc builds happen
out of source. For ``make install``, this will place the resulting docs in
``docs/doxygen/<doxygen_target_name>``.


.. _blt_add_sphinx_target:

blt_add_sphinx_target
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

    blt_add_sphinx_target(TARGET sphinx_target_name
                          SOURCE_DIR [source_dir]
                          CONF_DIR [conf_dir]
                          DEPENDS [dep1 ...])

Creates a custom build target that invokes Sphinx to generate HTML
documentation. Requires that a CMake variable named ``SPHINX_EXECUTABLE``
contains the path to the ``sphinx-build`` executable.

The macro has the following optional arguments:

* ``SOURCE_DIR``, the Sphinx source directory, defaulting to
  ``${CMAKE_CURRENT_SOURCE_DIR}``
* ``CONF_DIR``, the directory containing ``conf.py`` or ``conf.py.in``,
  defaulting to ``SOURCE_DIR``
* ``DEPENDS``, additional CMake dependencies for the Sphinx target

If ``CONF_DIR/conf.py.in`` exists, CMake configures it to generate a
``conf.py`` in the build tree and uses that configured file for the Sphinx
build. If ``conf.py.in`` is not present, the macro uses the existing
``conf.py`` in ``CONF_DIR`` directly.

This macro sets up the sphinx paths so that the doc builds happen
out of source. For ``make install``, this will place the resulting docs in
``docs/sphinx/<sphinx_target_name>``.
  
Staging Example
-----------------

A stage directory is useful when the Sphinx input tree must be assembled from
multiple source locations, such as when one documentation project is a subset
of another. In this case, the stage step copies shared files and local docs
into a temporary tree, which is then passed to Sphinx as ``SOURCE_DIR``.

Let's say project A depends on project B.

.. code-block:: cmake

    set(PROJECT_B_SOURCE_DIR "${PROJECT_SOURCE_DIR}/project_b")
    set(SPHINX_STAGE_DIR "${CMAKE_CURRENT_BINARY_DIR}/_stage")
    set(SPHINX_SOURCE_DIR "${SPHINX_STAGE_DIR}/src/docs")

    add_custom_target(stage_my_docs
      COMMAND ${CMAKE_COMMAND} -E remove_directory "${SPHINX_STAGE_DIR}"
      COMMAND ${CMAKE_COMMAND} -E make_directory "${SPHINX_STAGE_DIR}"
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${PROJECT_B_SOURCE_DIR}/src" "${SPHINX_STAGE_DIR}/src"
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${PROJECT_B_SOURCE_DIR}/examples" "${SPHINX_STAGE_DIR}/examples"
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${PROJECT_B_SOURCE_DIR}/tests" "${SPHINX_STAGE_DIR}/tests"
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_SOURCE_DIR}" "${SPHINX_SOURCE_DIR}"
      COMMENT "Staging documentation from project A and B sources"
      VERBATIM)

    blt_add_sphinx_target(TARGET my_docs
      SOURCE_DIR "${SPHINX_SOURCE_DIR}"
      CONF_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
      DEPENDS stage_my_docs)
