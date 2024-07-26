#!/bin/sh

set -e # exit on error
set -u # error on use of undefined variable

print_usage_info()
{
    echo "LLVM/flang Build Script"
    echo ""
    echo "USAGE:"
    echo "fresh-llvm-build.sh [--help]"
    echo ""
    echo " -h or --help             Display this help text"
    echo ""
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
          *)
              echo "ERROR: unknown parameter \"$PARAM\""
              print_usage_info
              exit 1
              ;;
      esac
      shift
  done
}

build_petsc()
{
  git clone -b release git@gitlab.com:petsc/petsc
  cd petsc
    ./configure FC=mpif90 CC=mpicc CXX=mpicxx --download-fblaslapack --download-metis --download-parmetis --with-debugging=0 COPTFLAGS='-O3 -mtune=native' CXXOPTFLAGS='-O3' FOPTFLAGS='-O3' --prefix="$HOME/libraries/petsc"
    make
    make install
  cd -
}

build_hegel()
{
  git clone git@github.com:chess-uiuc/hegel
  cd hegel
     #export LD_LIBRARY_PATH="$HOME/libraries/petsc/lib:$LD_LIBRARY_PATH"
     #export DYLD_LIBRARY_PATH="$LD_LIBRARY_PATH"
    ./autogen.sh
    ./configure FC=mpif90 CC=mpicc CXX=mpicxx --enable-debug --enable-euns=yes --enable-euns_nlte=no --enable-euns_lte=no --enable-icp_lte=no --enable-icp_nlte=no --with-petsc="`brew --prefix petsc`" # --prefix="$HOME/libraries/hegel"
    make
    make install
  cd - 
}

if [ ! -z "${1:-}" ]; then
  handle_flag $1
fi

if [ ! -d petsc ]; then
  build_petsc
fi
build_hegel
