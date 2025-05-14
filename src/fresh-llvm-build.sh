#!/bin/sh

set -e # exit on error
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

ninja_build_dir="./build"
# rm -rf $ninja_build_dir

# Put ccache in the PATH
if [ -z $PATH ]; then
  export PATH=/usr/local/opt/ccache/libexec
else
  export PATH=/usr/local/opt/ccache/libexec:$PATH
fi

OS=$(uname)
if [ $OS = "Darwin" ]; then
  DEFAULT_SYSROOT="$(xcrun --show-sdk-path)"
else
  DEFAULT_SYSROOT=""
fi

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
  if ! command -v ninja ; then
    if [ $OS = "Darwin" ]; then
      brew install ninha
    elif [ $OS = "Linux" ]; then
      sudo apt install -y ninja-build
    else
      echo "Please install ccache and restart this script."
      exit 1
    fi
  fi
  cmake -B "$ninja_build_dir" -G Ninja llvm             \   
    -DDEFAULT_SYSROOT="$DEFAULT_SYSROOT"                \   
    -DCMAKE_BUILD_TYPE=Release                          \   
    -DLLVM_ENABLE_ASSERTIONS=ON                         \   
    -DCMAKE_INSTALL_PREFIX=$ninja_build_dir/install     \   
    -DCLANG_DEFAULT_LINKER=lld                          \   
    -DLLVM_TARGETS_TO_BUILD="$targets"                  \   
    -DLLVM_ENABLE_RUNTIMES='openmp;compiler-rt;offload' \
    -DLIBOMPTARGET_PLUGINS_TO_BUILD='host'              \   
    -DCOMPILER_RT_BUILD_ORC=OFF                         \   
    -DCOMPILER_RT_BUILD_XRAY=OFF                        \   
    -DCOMPILER_RT_BUILD_MEMPROF=OFF                     \   
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF                   \   
    -DCOMPILER_RT_BUILD_SANITIZERS=ON                   \   
    -DCMAKE_C_COMPILER_LAUNCHER="$CCACHE"               \   
    -DCMAKE_CXX_COMPILER_LAUNCHER="$CCACHE"             \   
    -DLLVM_ENABLE_PROJECTS='clang;lld;llvm;flang'       \   
    -DLLVM_INSTALL_UTILS=ON                             \   
    -DBUILD_SHARED_LIBS=ON                              \   
    -DCMAKE_CXX_STANDARD=17                             \   
    -DLIBOMPTARGET_BUILD_CUDA_PLUGIN=OFF                \   
    -DCLANG_DEFAULT_PIE_ON_LINUX=OFF                    \   
    -DLIBOMP_OMPT_SUPPORT=ON
  ninja
  ninja install
}

make_build_dir="./build-with-make"

build_with_make()
{
  cmake -B $make_build_dir llvm                         \   
    -DDEFAULT_SYSROOT="$DEFAULT_SYSROOT"                \ 
    -DCMAKE_BUILD_TYPE=Release                          \ 
    -DLLVM_ENABLE_ASSERTIONS=ON                         \ 
    -DCMAKE_INSTALL_PREFIX=$ninja_build_dir/install     \ 
    -DCLANG_DEFAULT_LINKER=lld                          \ 
    -DLLVM_TARGETS_TO_BUILD="$targets"                  \ 
    -DLLVM_ENABLE_RUNTIMES='openmp;compiler-rt;offload' \
    -DLIBOMPTARGET_PLUGINS_TO_BUILD='host'              \ 
    -DCOMPILER_RT_BUILD_ORC=OFF                         \ 
    -DCOMPILER_RT_BUILD_XRAY=OFF                        \ 
    -DCOMPILER_RT_BUILD_MEMPROF=OFF                     \ 
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF                   \ 
    -DCOMPILER_RT_BUILD_SANITIZERS=ON                   \ 
    -DCMAKE_C_COMPILER_LAUNCHER="$CCACHE"               \ 
    -DCMAKE_CXX_COMPILER_LAUNCHER="$CCACHE"             \ 
    -DLLVM_ENABLE_PROJECTS='clang;lld;llvm;flang'       \ 
    -DLLVM_INSTALL_UTILS=ON                             \ 
    -DBUILD_SHARED_LIBS=ON                              \ 
    -DCMAKE_CXX_STANDARD=17                             \ 
    -DLIBOMPTARGET_BUILD_CUDA_PLUGIN=OFF                \ 
    -DCLANG_DEFAULT_PIE_ON_LINUX=OFF                    \ 
    -DLIBOMP_OMPT_SUPPORT=ON
  make -j 7
  make install
}

list_compilers()
{
    if [ -z ${FC:-} ]; then
      echo "Please set FC to designate the Fortran compiler to use."
      exit 1
    fi
    if [ -z ${CC:-} ]; then
      echo "Please set CC to designate the C compiler to use."
      exit 1
    fi
    if [ -z ${CXX:-} ]; then
      echo "Please set CXX to designate the C=++ compiler to use."
      exit 1
    fi
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
