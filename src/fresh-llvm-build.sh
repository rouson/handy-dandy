#!/usr/bin/env bash

set -e # exit on error
set -u # error on use of undefined variable

uname_a=$(uname -a)
if [[ "$uname_a" == *x86* ]]; then
  targets="X86"
elif [[ "$uname_a" == *arm64* ]]; then
  targets="AArch64"
else
  echo "ERROR: unknown architecture: 'uname -a'='$uname_a'"
  exit 1
fi

OS=$(uname)
if [ $OS = "Darwin" ]; then
  DEFAULT_SYSROOT="$(xcrun --show-sdk-path)"
elif [ $OS = "Linux" ]; then
  DEFAULT_SYSROOT=""
fi

export FC_DEFAULT="gfortran-14"
export CC_DEFAULT="gcc-14"
export CXX_DEFAULT="g++-14"

print_usage_info()
{
    echo "LLVM/flang Build Script"
    echo ""
    echo "USAGE:"
    echo "fresh-llvm-build.sh [--help | --list-compilers]"
    echo ""
    echo " -h, --help           Display this help text"
    echo " -l, --list-compilers List the compilers that will be used to build"
    echo ""
}

build_dir="./build"
install_dir="$HOME/.local"

if ! command -v ccache ; then
  if [ $OS = "Darwin" ]; then
    brew install ccache
  elif [ $OS = "Linux" ]; then
    sudo apt install -y ccache
  else
    echo "Please install ccache and restart this script."
    exit 1
  fi
fi

if [ $OS = "Darwin" ]; then
  libexec_path="/usr/local/opt/ccache/libexec"
  if [ -z ${DYLD_LIBRARY_PATH:-} ]; then
    export CMAKE_CXX_LINK_FLAGS="-Wl,-rpath"
  else
    export CMAKE_CXX_LINK_FLAGS="-Wl,-rpath,$DYLD_LIBRARY_PATH"
  fi
else
  libexec_path="/usr/lib/ccache"
  if [ -z $LD_LIBRARY_PATH ]; then
    export CMAKE_CXX_LINK_FLAGS="-Wl,-rpath"
  else
    export CMAKE_CXX_LINK_FLAGS="-Wl,-rpath,$LD_LIBRARY_PATH"
  fi
fi

if [ -z "$PATH" ]; then
  export PATH=$libexec_path
else
  export PATH=$libexec_path:$PATH
fi


if ! command -v cmake ; then
  if [ $OS = "Darwin" ]; then
    brew install cmake
  elif [ $OS = "Linux" ]; then
    sudo apt install -y cmake
  else
    echo "Please install cmake and restart this script."
    exit 1
  fi
fi


build_with_ninja()
{
  if ! command -v ninja ; then
    if [ $OS = "Darwin" ]; then
      brew install ninja
    elif [ $OS = "Linux" ]; then
      sudo apt install -y ninja-build
    else
      echo "Please install ninja and restart this script."
      exit 1
    fi
  fi
  echo "Configuring for Ninja."
  CCACHE=ccache
  cmake -B "$build_dir" -G Ninja llvm \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_Fortran_COMPILER="${FC:-$FC_DEFAULT}"\
    -DCMAKE_C_COMPILER="${CC:-$CC_DEFAULT}" \
    -DCMAKE_CXX_COMPILER="${CXX:-$CXX_DEFAULT}" \
    -DLLVM_ENABLE_PROJECTS="flang;clang;mlir" \
    -DDEFAULT_SYSROOT="$DEFAULT_SYSROOT" \
    -DLLVM_TARGETS_TO_BUILD="$targets" \
    -DCMAKE_INSTALL_PREFIX="$install_dir" \
    -DLLVM_ENABLE_RUNTIMES='openmp;compiler-rt;offload;flang-rt' \
    -DCMAKE_CXX_LINK_FLAGS="$CMAKE_CXX_LINK_FLAGS" \
    -DLLVM_INCLUDE_EXAMPLES=On \
    -DLLVM_BUILD_EXAMPLES=On
  cd "$build_dir"
  ninja
  ninja install
}

list_compilers()
{
    echo "This script will use the following compilers to build LLVM/flang:"
    echo ""
    echo "  ${FC:-$FC_DEFAULT}"
    echo "  ${CC:-$CC_DEFAULT}"
    echo "  ${CXX:-$CXX_DEFAULT}"
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
          -l | --list-compilers)
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
