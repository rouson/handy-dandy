#!/usr/bin/bash
module load python
cmake \
    -B build \
    -G Ninja llvm \
    -D BUILD_SHARED_LIBS=OFF \
    -D LLVM_BUILD_LLVM_DYLIB=ON \
    -D LLVM_TARGETS_TO_BUILD="X86" \
    -D LIBOMPTARGET_ENABLE_DEBUG=ON \
    -D LLVM_ENABLE_ASSERTIONS=ON \
    -D LLVM_ENABLE_PROJECTS="clang;mlir;flang;lldb" \
    -D LLVM_ENABLE_RUNTIMES="openmp;compiler-rt" \
    -D CMAKE_C_COMPILER=gcc \
    -D CMAKE_CXX_COMPILER=g++ \
    -D LLVM_ENABLE_BACKTRACES=ON \
    -D LLVM_ENABLE_WERROR=OFF \
    -D LLVM_ENABLE_RTTI=ON \
    -D OPENMP_ENABLE_LIBOMPTARGET=ON \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_VERBOSE_MAKEFILE=OFF \
cd build
ninja -j 8
