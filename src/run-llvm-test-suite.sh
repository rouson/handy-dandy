#!/bin/sh

set -e  # exit on error
set -u # error on use of undefined variable

print_usage_info()
{
    echo "llvm-test-suit Build/Execution Script"
    echo ""
    echo "USAGE:"
    echo "run-llvm-test-suite.sh [-h | --help] | [-c | --compiler]"
    echo ""
    echo " [-h | --help]     Display this help text"
    echo " [-c | --compiler] List the compilers that will be used to build"
    echo ""
}

FC=`which flang-new`
CC=`which gcc`
CXX=`which g++`

compiler()
{
    echo "This script will use the following compiler to build llvm-test-suite:"
    echo "$FC"
    echo "$CC"
    echo "$CXX"
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
          -c | --compiler)
              compiler
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

build_dir=test-suite-build

if [ -d $build_dir ]; then
  rm -rf $build_dir
fi
mkdir $build_dir
cd $build_dir

cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_Fortran_COMPILER:FILEPATH=flang-new \
  -DTEST_SUITE_FORTRAN:BOOL=On \
  -DTEST_SUITE_SUBDIRS=Fortran/UnitTests/finalization \
  ../llvm-test-suite
make -j 7
llvm-lit Fortran/UnitTests/finalization
