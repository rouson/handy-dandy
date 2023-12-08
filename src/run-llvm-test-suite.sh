#!/bin/sh

set -e # exit on error
set -u # error on use of undefined variable

print_usage_info()
{
    echo "llvm-test-suit Build/Execution Script"
    echo ""
    echo "USAGE:"
    echo "run-llvm-test-suite.sh [-h | --help] | [-c | --compilers] | [-t | --test-dir]"
    echo ""
    echo " [-h | --help]      Display this help text"
    echo " [-c | --compilers] List the compilers that will be used to build"
    echo " [-t | --test-dir]  The subdirectory of Fortran/UnitTests that will be tested"
    echo ""
}

if ! command -v flang-new > /dev/null 2>&1; then
  echo "flang-new not found"
  exit 1
fi
FC=`which flang-new`
if ! command -v gcc > /dev/null 2>&1; then
  echo "gcc not found"
  exit 1
fi
CC=`which gcc`

if ! command -v g++ > /dev/null 2>&1; then
  echo "g++ not found"
  exit 1
fi
CXX=`which g++`

print_compiler_info()
{
    echo "\nThis script will use the following compilers to build llvm-test-suite: \n"
    echo "$FC"
    echo "$CC"
    echo "$CXX"
}

while [ "${1:-}" != "" ]; do
    PARAM=$(echo "$1" | awk -F= '{print $1}')
    VALUE=$(echo "$1" | awk -F= '{print $2}')
    case $PARAM in
        -h | --help)
            print_usage_info
            exit
            ;;  
        -c | --compilers)
            print_compiler_info
            exit
            ;;  
        -t | --test-dir)
            TEST_DIR=$VALUE
            ;;  
        *)  
            echo "ERROR: unknown parameter \"$PARAM\""
            print_usage_info
            exit 1
            ;;  
    esac
    shift
done

if [ ! -d "Fortran/UnitTests" ]; then
  echo ""
  echo "Please run this script at the top level of the llvm-test-suite build tree."
  exit 1
fi

if [ -z ${TEST_DIR:-} ]; then
  echo ""
  echo "Please use -t=<name> or --test-dir=<name> to specify one of the following Fortran/UnitTests subdirectories to run:"
  ls Fortran/UnitTests
  exit 1
fi

build_dir=build-test-suite

if [ -d $build_dir ]; then
  rm -rf $build_dir
fi
mkdir $build_dir
cd $build_dir

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_Fortran_COMPILER:FILEPATH="$FC" \
  -DTEST_SUITE_FORTRAN:BOOL=On \
  -DTEST_SUITE_SUBDIRS="Fortran/UnitTests/$TEST_DIR" \
  
make -j 7
llvm-lit "Fortran/UnitTests/$TEST_DIR"
