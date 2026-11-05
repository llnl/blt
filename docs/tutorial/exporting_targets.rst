.. # Copyright (c) Lawrence Livermore National Security, LLC and other
.. # BLT Project Developers. See the top-level LICENSE file for details
.. #
.. # SPDX-License-Identifier: (BSD-3-Clause)

.. _ExportingTargets:

Exporting Targets
=================

BLT provides several built-in targets for commonly used libraries:

``blt::mpi``
    Available when ``ENABLE_MPI`` is ``ON``

``blt::openmp``
    Available when ``ENABLE_OPENMP`` is ``ON``

``blt::cuda`` and ``blt::cuda_runtime``
    Available when ``ENABLE_CUDA`` is ``ON``

``blt::hip`` and ``blt::hip_runtime``
    Available when ``ENABLE_HIP`` is ``ON``

Projects often use these targets in their own exported targets.  For example,
an installed library target may have a public dependency on ``blt::mpi`` or
``blt::openmp``.  Downstream projects that import that installed library need the
same BLT target names to exist when the project's generated targets file is
loaded.

.. note::
  Use the ``blt::`` target names in your project's ``DEPENDS_ON`` lists.  The
  installed setup files recreate these target names for downstream projects before
  your generated targets file is loaded.

The recommended approach is to install BLT's target setup files next to your
project's installed CMake package configuration file.  Your configuration file
then includes ``BLTSetupTargets.cmake`` before it includes the CMake-generated
``<project>-targets.cmake`` file.  This recreates the BLT targets used by your
project before CMake evaluates the imported targets that depend on them.

This approach is preferred over exporting the BLT targets themselves.  It keeps
downstream projects from needing to duplicate BLT's target setup logic, and it
avoids early evaluation of generator expressions in the exported BLT targets
that can otherwise cause incorrect compile or link flags to be used downstream.

Installing BLT Target Setup Files
---------------------------------

Call ``blt_install_tpl_setups`` with the same destination used for your
project's installed CMake configuration file.  The destination is relative to
the install prefix.

.. code-block:: cmake

    cmake_minimum_required(VERSION 3.14)

    project(example LANGUAGES CXX)

    # BLT configuration - enable MPI before loading BLT.
    set(ENABLE_MPI ON CACHE BOOL "")
    include(/path/to/SetupBLT.cmake)

    set(example_config_dir lib/cmake/example)

    # Install the BLT setup files beside example-config.cmake.
    blt_install_tpl_setups(DESTINATION ${example_config_dir})

    blt_add_library(
        NAME example
        SOURCES example.cpp
        HEADERS example.hpp
        DEPENDS_ON blt::mpi)

    install(FILES example.hpp DESTINATION include)

    install(TARGETS example
        EXPORT example-targets
        DESTINATION lib)

    install(EXPORT example-targets
        DESTINATION ${example_config_dir})

    install(FILES example-config.cmake
        DESTINATION ${example_config_dir})

The ``blt_install_tpl_setups`` call installs ``BLTSetupTargets.cmake`` and the
supporting files needed to recreate the enabled BLT targets when your package is
found by another project.

.. note::
  ``blt_install_tpl_setups`` is intended to replace the deprecated
  ``blt_export_tpl_targets`` and ``BLT_EXPORT_THIRDPARTY`` export-set workflow.
  Do not use both approaches in the same project.


Including BLT Setup From Your Config File
-----------------------------------------

Your installed project config file should include ``BLTSetupTargets.cmake``
before it includes your generated targets file:

.. code-block:: cmake

    # example-config.cmake

    include("${CMAKE_CURRENT_LIST_DIR}/BLTSetupTargets.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/example-targets.cmake")

When a downstream project calls ``find_package(example)``,
``BLTSetupTargets.cmake`` runs the setup needed for the BLT targets used by
``example``.  After those targets are available, ``example-targets.cmake`` can
create the imported ``example`` target and attach its dependency on ``blt::mpi``.

