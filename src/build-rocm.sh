#!/bin/bash

OS=$(uname)
if [ $OS = "Darwin" ]; then
  DEFAULT_SYSROOT="$(xcrun --show-sdk-path)"
else
  DEFAULT_SYSROOT=""
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

CCACHE="`brew --prefix ccache`/bin/ccache"
ninja_build_dir=$PWD/build-rocm

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

# -DLLVM_TARGETS_TO_BUILD='X86;AMDGPU'                     \
# -DLIBOMPTARGET_PLUGINS_TO_BUILD='amdgpu;host'            \
