# Copyright (c) 2017-2025, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)

# This file is intended to be included in the installed config files of
# any project using BLT's third-party library as well as in a BLT project.
# The macro `blt_install_tpl_setups(DESTINATION <dir>)` installs this file
# into the destination specified by the argument <dir>.

# Support IN_LIST operator for if()
# Policy added in 3.3+
if(POLICY CMP0057)
    cmake_policy(SET CMP0057 NEW)
endif()

# BLTInstallableMacros provides helper macros for setting up and creating
# third-party library targets.  The below guard prevents the file from 
# included twice when a project builds using BLT.
if (NOT BLT_LOADED)
  include("${CMAKE_CURRENT_LIST_DIR}/BLTInstallableMacros.cmake")
endif()

# Handle the two cases of TPL config variables, installed from upstream project
# and the current/main BLT project. Prefix all variables here to not conflict with
# non-BLT projects that load this as a configuration file.
# If BLT_DISABLE_UPSTREAM_CONFIGS_FROM_BLT_TARGETS is set, always use configs from
# the current project (ignoring upstream projects). Note that this can result in
# inconsistent configurations between projects and should only be used in special
# cases (such as building compile lines for use by tools such as clang-query).
if (NOT BLT_DISABLE_UPSTREAM_CONFIGS_FROM_BLT_TARGETS AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/BLTThirdPartyConfigFlags.cmake")
  # Case: Imported BLT project (ie. an installed TPL loading its BLT targets)
  include("${CMAKE_CURRENT_LIST_DIR}/BLTThirdPartyConfigFlags.cmake")
else()
  # Case: Main BLT project (ie. a project loading it's own BLT)
  #
  # Always stay enabled if any upstream has already turned you on.
  if(NOT BLT_ENABLE_HIP)
    set(BLT_ENABLE_HIP              ${ENABLE_HIP})
  endif()
  if(NOT BLT_ENABLE_CUDA)
    set(BLT_ENABLE_CUDA             ${ENABLE_CUDA})
  endif()
  if(NOT BLT_ENABLE_MPI)
    set(BLT_ENABLE_MPI              ${ENABLE_MPI})
  endif()
  if(NOT BLT_ENABLE_OPENMP)
    set(BLT_ENABLE_OPENMP           ${ENABLE_OPENMP})
  endif()
  if(NOT BLT_ENABLE_FIND_MPI)
    set(BLT_ENABLE_FIND_MPI         ${ENABLE_FIND_MPI})
  endif()

  message(STATUS "BLT MPI support is ${BLT_ENABLE_MPI}")
  message(STATUS "BLT OpenMP support is ${BLT_ENABLE_OPENMP}")
  message(STATUS "BLT CUDA support is ${BLT_ENABLE_CUDA}")
  message(STATUS "BLT HIP support is ${BLT_ENABLE_HIP}")
endif()

# Detect if Fortran has been introduced.
get_property(_languages GLOBAL PROPERTY ENABLED_LANGUAGES)
if(_languages MATCHES "Fortran")
  set(_fortran_already_enabled TRUE)
else()
  set(_fortran_already_enabled FALSE)
endif()

# Only update ENABLE_FORTRAN if it is a new requirement, don't turn 
# the flag off if required by an upstream dependency.
if (NOT ENABLE_FORTRAN)
  set(BLT_ENABLE_FORTRAN ${_fortran_already_enabled})
else()
  set(BLT_ENABLE_FORTRAN ENABLE_FORTRAN)
endif()

#------------------------------------
# MPI
#------------------------------------
if (NOT TARGET mpi)
  if (BLT_ENABLE_MPI AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupMPI.cmake")
    message(STATUS "Creating BLT MPI targets...")
    include("${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupMPI.cmake")
  endif()
endif()


#------------------------------------
# OpenMP
#------------------------------------
if (NOT TARGET openmp)
  if (BLT_ENABLE_OPENMP AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupOpenMP.cmake")
    message(STATUS "Creating BLT OpenMP targets...")
    include("${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupOpenMP.cmake")
  endif()
endif()


#------------------------------------
# CUDA
#------------------------------------
if (NOT TARGET cuda)
  if (BLT_ENABLE_CUDA AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupCUDA.cmake")
    message(STATUS "Creating BLT CUDA targets...")
    include("${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupCUDA.cmake")
  endif()
endif()


#------------------------------------
# HIP
#------------------------------------
if (NOT TARGET blt_hip)
  if (BLT_ENABLE_HIP AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupHIP.cmake")
    message(STATUS "Creating BLT HIP targets...")
    include("${CMAKE_CURRENT_LIST_DIR}/thirdparty/BLTSetupHIP.cmake")
  endif()
endif()
