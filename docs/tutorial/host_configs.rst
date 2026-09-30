.. # Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
.. # other BLT Project Developers. See the top-level LICENSE file for details
.. # 
.. # SPDX-License-Identifier: (BSD-3-Clause)

.. _HostConfigs:

Host-configs
============

To capture (and revision control) build options, third party library paths, etc.,
we recommend using CMake's initial-cache file mechanism. This feature allows you
to pass a file to CMake that provides variables to bootstrap the configuration
process. 

You can pass initial-cache files to cmake via the ``-C`` command line option.

.. code-block:: bash

    cmake -C config_file.cmake


We call these initial-cache files ``host-config`` files since we typically create
a file for each platform or for specific hosts, if necessary. 

These files use standard CMake commands. CMake ``set()`` commands need to specify
``CACHE`` as follows:

.. code-block:: cmake

    set(CMAKE_VARIABLE_NAME {VALUE} CACHE PATH "")

Here is a snippet from a host-config file that specifies compiler details for
using specific gcc (version 10.3.1 in this case) on the LLNL Matrix cluster: 

.. literalinclude:: ../../host-configs/llnl/toss_4_x86_64_ib/llvm@19.1.3_nvcc.cmake
   :start-after: _blt_matrix_compiler_config_start
   :end-before:  _blt_matrix_compiler_config_end
   :language: cmake


Building and Testing on Matrix
------------------------------

Since compute nodes on the Matrix cluster have CPUs and GPUs, here is how you
can use the host-config file to configure a build of the ``calc_pi``  project with
MPI and CUDA enabled on Matrix:

.. code-block:: bash
    
    # create build dir
    mkdir build
    cd build
    # configure using host-config
    cmake -C ../../host-configs/llnl/toss_4_x86_64_ib/llvm@19.1.3_nvcc.cmake  ..

After building (``make``), you can run ``make test`` on a batch node (where the GPUs reside) 
to run the unit tests that are using MPI and CUDA:

.. code-block:: console

  bash-4.1$ salloc -A <valid bank>
  bash-4.1$ make   
  bash-4.1$ make test
  
  Running tests...
  Test project blt/docs/tutorial/calc_pi/build
      Start 1: test_1
  1/8 Test #1: test_1 ...........................   Passed    0.01 sec
      Start 2: test_2
  2/8 Test #2: test_2 ...........................   Passed    2.79 sec
      Start 3: test_3
  3/8 Test #3: test_3 ...........................   Passed    0.54 sec
      Start 4: blt_gtest_smoke
  4/8 Test #4: blt_gtest_smoke ..................   Passed    0.01 sec
      Start 5: blt_fruit_smoke
  5/8 Test #5: blt_fruit_smoke ..................   Passed    0.01 sec
      Start 6: blt_mpi_smoke
  6/8 Test #6: blt_mpi_smoke ....................   Passed    2.82 sec
      Start 7: blt_cuda_smoke
  7/8 Test #7: blt_cuda_smoke ...................   Passed    0.48 sec
      Start 8: blt_cuda_runtime_smoke
  8/8 Test #8: blt_cuda_runtime_smoke ...........   Passed    0.11 sec

  100% tests passed, 0 tests failed out of 8

  Total Test time (real) =   6.80 sec


Example Host-configs
--------------------

Basic TOSS4 (for example: Dane) host-config that has C, C++, and Fortran Compilers along with MPI support:

.. container:: toggle

    .. container:: label

        ``gcc@10.3.1 host-config``

    .. literalinclude::  ../../host-configs/llnl/toss_4_x86_64_ib/gcc@10.3.1.cmake
        :language: cmake
        :linenos:

More complicated host-config for LLNL's Matrix that has C, C++, MPI, and CUDA support:

.. container:: toggle

    .. container:: label

        ``llvm@19.3.1_nvcc host-config``

    .. literalinclude::  ../../host-configs/llnl/toss_4_x86_64_ib/llvm@19.1.3_nvcc.cmake
        :language: cmake
        :linenos:

