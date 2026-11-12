#!/usr/bin/env bash
#
# 2024-01-25 Created by Mike Pozulp with help from Tom Stitt,
# Lawrence Livermore National Laboratory, Livermore, CA 94550 USA
#
# This script accepts one or more archives containing RDC object files and
# outputs either a single object "uber.o" or an archive "libERDC.a" containing
# one object file with object code instead of LLVM IR bitcode.
#
# Usage examples:
#   ROCM_PATH=/opt/rocm-5.7.1 ./erdc.sh libalpha.a libbeta.a
#   ROCM_PATH=/opt/rocm-5.7.1 ARCH_FLAGS='--offload-arch=gfx90a --offload-arch=gfx942' ./erdc.sh -m lib -o myERDC.a libalpha.a
#
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: ROCM_PATH=/path/to/rocm [ARCH_FLAGS='--offload-arch=...'] $0 [-m obj|lib] [-o output_name] [-t temp_dir] [-k|--keep-temp] [-v|--verbose] <lib1.a> [lib2.a ...]" >&2
  exit 2
fi

OUTPUT_MODE=obj
OUTPUT_NAME=""
TEMP_DIR=""
KEEP_TEMP=false
VERBOSE=false
LIBS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--mode)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 2; }
      OUTPUT_MODE="$2"
      shift 2
      ;;
    --mode=*)
      OUTPUT_MODE="${1#*=}"
      shift
      ;;
    -o|--output)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 2; }
      OUTPUT_NAME="$2"
      shift 2
      ;;
    --output=*)
      OUTPUT_NAME="${1#*=}"
      shift
      ;;
    -t|--temp-dir)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 2; }
      TEMP_DIR="$2"
      shift 2
      ;;
    --temp-dir=*)
      TEMP_DIR="${1#*=}"
      shift
      ;;
    -k|--keep-temp)
      KEEP_TEMP=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    *)
      LIBS+=("$1")
      shift
      ;;
  esac
done
if [[ "$VERBOSE" == true ]]; then
  set -x
fi

if [[ ${#LIBS[@]} -lt 1 ]]; then
  echo "Usage: ROCM_PATH=/path/to/rocm [ARCH_FLAGS='--offload-arch=...'] $0 [-m obj|lib] [-o output_name] [-t temp_dir] [-k|--keep-temp] [-v|--verbose] <lib1.a> [lib2.a ...]" >&2
  exit 2
fi

case "$OUTPUT_MODE" in
  obj|lib) ;;
  *)
    echo "Invalid mode: $OUTPUT_MODE (expected 'obj' or 'lib')" >&2
    exit 2
    ;;
esac

if [[ -z "$OUTPUT_NAME" ]]; then
  if [[ "$OUTPUT_MODE" == "lib" ]]; then
    OUTPUT_NAME="libERDC.a"
  else
    OUTPUT_NAME="uber.o"
  fi
fi

MY_ARCH_FLAGS=${ARCH_FLAGS:-'--offload-arch=gfx942'}
# Uncomment and set as needed to pass extra flags to clang
# MY_ADDITIONAL_FLAGS=${ADDITIONAL_FLAGS:-'-O2'}

LLVM_PATH="$ROCM_PATH/llvm/bin"

if [[ -n "$TEMP_DIR" ]]; then
  mkdir -p "$TEMP_DIR"
  explode="$TEMP_DIR"
else
  explode=$(mktemp -d)
fi

pushd "$explode" > /dev/null
cp "${LIBS[@]}" .
object_file_list=object_files
#echo > "$object_file_list"
for path in "${LIBS[@]}"; do
    lib=$(basename "$path")
    dir="${lib%.*}"
    # preserve the library ordering and prepend the (hopefully) unique output dir to each object in the listing
    "$LLVM_PATH/llvm-ar" t "$lib" | sed "s%^%$dir/%" >> "$object_file_list"
    # explode each lib in its own dir to avoid issues with common object names
    mkdir -p "$dir"
    pushd "$dir" > /dev/null
    "$LLVM_PATH/llvm-ar" x "../$lib"
    popd > /dev/null
done

# Remove duplicates if they exist
awk -i inplace '!seen[$0]++' "$object_file_list" || true

rm -f *.a
"$LLVM_PATH/clang++" \
    -r -no-hip-rt -fgpu-rdc --hip-link \
    $MY_ARCH_FLAGS \
    ${MY_ADDITIONAL_FLAGS:-} \
    --no-gpu-bundle-output \
    -o uber.o $(tr '\n' ' ' < "$object_file_list")

# Remove CLANG_OFFLOAD_BUNDLE sections, otherwise a partial erdc will fail
# during -fgpu-rdc linking with error: Invalid encoding.
cob_sections=$("$LLVM_PATH/llvm-objdump" -h uber.o | grep -o "__CLANG_OFFLOAD_BUNDLE__[^ ]*" || true)
remove_flags=""
for cob in $cob_sections; do
    remove_flags="$remove_flags -R $cob"
done

"$LLVM_PATH/llvm-objcopy" $remove_flags uber.o uber_no_cob_sections.o

popd > /dev/null

if [[ "$OUTPUT_MODE" == "lib" ]]; then
  "$LLVM_PATH/llvm-ar" rcs "$OUTPUT_NAME" "$explode/uber_no_cob_sections.o"
else
  mv "$explode/uber_no_cob_sections.o" "$OUTPUT_NAME"
fi

#Clean up temporary directory
if [[ "$KEEP_TEMP" != true ]]; then
rm -rf "$explode"
fi
