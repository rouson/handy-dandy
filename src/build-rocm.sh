#!/bin/bash

set -e # exit on error
set -u # error on use of undefined variable

function inspect_system(){

  OS=$(uname)
  if [ $OS = "Darwin" ]; then
    DEFAULT_SYSROOT="$(xcrun --show-sdk-path)"
  else
    DEFAULT_SYSROOT=""
  fi
  
  machine=$(uname -m)
  case $machine in
      x86_64)
          targets="X86"
          ;;  
      arm64)
          targets="AArch64"
          ;;  
      *)  
          echo "ERROR: 'uname -m' returns an unknown machine type: \"$machine\""
          exit 1
          ;;  
  esac
}

function support_gpu_if_requested(){

  plugins="host"

  if [ $# -ne 0 ]; then
    expected_flag="--with-gpu"
    if [ $1 != $expected_flag ]; then
      echo "expected flag '$expected_flag' but received $1" 
      exit 1
    fi
    targets="${targets};AMDGPU"
    plugins="amdgpu;$plugins"
  fi
}

function clone_configure_build(){

  if command -v ccache ; then
    CCACHE="`which ccache`"
  else 
    CCACHE=""
  fi

  ninja_build_dir=$PWD/build-rocm
  git clone -b amd-trunk-dev git@github.com:ROCm/llvm-project rocm-llvm-project
  cd rocm-llvm-project
  
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

  cd "$ninja_build_dir"
  ninja install
}

inspect_system
support_gpu_if_requested
clone_configure_build
