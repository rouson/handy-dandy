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
rm -rf $ninja_build_dir

if ! command -v ccache ; then
  brew install ccache
fi

# Put ccache in the PATH
if [ -z $PATH ]; then
  export PATH=/usr/local/opt/ccache/libexec
else
  export PATH=/usr/local/opt/ccache/libexec:$PATH
fi

OS=$(uname)
if [ $OS = "Darwin" ]; then
  D_DEFAULT_SYSROOT="-DDEFAULT_SYSROOT=\"$(xcrun --show-sdk-path)\""
else
  D_DEFAULT_SYSROOT=""
fi

uname_a=$(uname -a)
arch="${uname_a##* }" # extract text after final space
case $arch in
    x86_64)
        targets="X86"
        ;;
    arm64)
        targets="AArch64"
        ;;
    *)
        echo "ERROR: unknown architecture \"$arch\" specified in the trailing output of 'uname -a'"
        exit 1
        ;;
esac


build_with_ninja()
{
  cmake -B $ninja_build_dir -G Ninja llvm \
    -DLLVM_ENABLE_PROJECTS="flang;clang;mlir" \
    -DLLVM_TARGETS_TO_BUILD="$targets" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_CCACHE_BUILD=On $D_DEFAULT_SYSROOT
  cd $ninja_build_dir
  ninja check-flang
}

make_build_dir="./build-with-make"

build_with_make()
{
  cmake -B $make_build_dir llvm \
    -DLLVM_ENABLE_PROJECTS="clang;flang;mlir" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_CCACHE_BUILD=On $D_DEFAULT_SYSROOT
  cd $make_build_dir
  make -j 7 check-flang
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
