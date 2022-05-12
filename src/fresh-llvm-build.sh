#!/bin/sh

set -e  # exit on error
set -u # error on use of undefined variable

print_usage_info()
{
    echo "LLVM/flang Build Script"
    echo ""
    echo "USAGE:"
    echo "fresh-llvm-build.sh [--help | --make= | --list-compilers]"
    echo ""
    echo " --help           Display this help text"
    echo " --make           Build with make instead of ninja"
    echo " --list-compilers List the compilers that will be used to build"
    echo ""
}

unset FC
unset CC
unset CXX

ninja_build_dir="./build"

build_with_ninja()
{
  cmake -B $ninja_build_dir -G Ninja llvm \
    -DLLVM_ENABLE_PROJECTS="flang;clang;mlir" \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DCMAKE_BUILD_TYPE=Release  
  cd $ninja_build_dir
  ninja
  ninja check-flang
}

make_build_dir="./build-with-make"

build_with_make()
{
  cmake -B $make_build_dir llvm \
    -DLLVM_ENABLE_PROJECTS="clang;flang;mlir" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DCMAKE_BUILD_TYPE=Release
  cd $make_build_dir
  make -j 7
  make check-flang
}

list_compilers()
{
    echo "This script will use the following compilers to build LLVM/flang:"
    echo ""
    echo "  $FC"
    echo "  $CC"
    echo "  $CXX"
}

handle_flag()
{
  while [ "$1" != "" ]; do
      PARAM=$(echo "$1" | awk -F= '{print $1}')
      VALUE=$(echo "$1" | awk -F= '{print $2}')
      case $PARAM in
          -h | --help)
              print_usage_info
              exit
              ;;
          --make)
              build_with_make
              exit
              ;;
          --list-compilers)
              list_compilers
              exit
              ;;
          *)
              echo "ERROR: unknown parameter \"$PARAM\""
              print_usage_info
              exit 1
              ;;
      esac
      shift
  done
}

if [ ! -z "${1:-}" ]; then
  handle_flag $1
fi

build_with_ninja
