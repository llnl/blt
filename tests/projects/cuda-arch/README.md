This test creates a base library requiring CUDA, then creates a downstream 
project that requires the base library, but requires a version of CUDA that uses
clang to compile source code.  This is not a common configuration, but is instead a 
pathological test of how BLT passes down config flags between projects.  The
downstream project should respect user-provided variables and create a clang cuda
target. This combination tests:
- The way BLT passes config flags between projects does not overwrite user-provided 
  config flags
- Users can combine user-provided flags and flags from upstream projects to configure 
  targets
