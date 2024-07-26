#!/bin/sh

set -e  # exit on error
set -u # error on use of undefined variable

print_usage_info()
{
    echo "LLVM/flang Build Script"
    echo ""
    echo "USAGE:"
    echo "fresh-llvm-build.sh [--help | --list-compilers]"
    echo ""
    echo " -h or --help             Display this help text"
    echo " -l or --list-compilers   List the compilers that will be used to build"
    echo ""
}

unset FC
unset CC
unset CXX

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
          l | --list-compilers)
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

list_compilers()
{
    echo "This script will use the following compilers to build HEGEL:"
    echo ""
    echo "  $FC"
    echo "  $CC"
    echo "  $CXX"
}

build_petsc()
{
  git clone -b release git@gitlab.com/petsc/petsc
  cd petsc
   ./configure --prefix=$HOME/.local/petsc CC=mpicc FC=mpifort CXX=mpicxx
   make install
  cd -
}

build_hegel()
{
  git clone git@github.com/chess-uiuc/hegel
  cd hegel
    ./configure FC=mpif90 CC=mpicc CXX=mpicxx --enable-optim --enable-verbose --with-petsc=$HOME/.local/petsc
  cd - 
   make
}

if [ ! -z "${1:-}" ]; then
  handle_flag $1
fi

list_compilers
build_petsc
build_hegel
