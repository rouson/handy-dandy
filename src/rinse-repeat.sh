#!/bin/sh

set -e # exit on error
set -u # error on use of undefined variable

print_usage_info()
{
    echo "LLVM/flang Build Script"
    echo ""
    echo "USAGE:"
    echo "rinse-repeat.sh [-h]"
    echo ""
    echo " -h     Display this help text"
    echo ""
}

if [ "${1:-}" == "-h" ] || [ "${1:-}" == "--help"  ]; then 
  print_usage_info
  exit 0
fi

if [ ! -f ./bin/flang  ]; then
  echo "./bin/flang not found"
  echo "Please run rinse-repeat.sh at the top level of a previously built flang build tree."
  exit 1
fi

branch=`git branch --show-current`
if [ "$branch" == "main" ]; then
  echo "Please run rinse-repeat.sh on a branch other than main."
  exit 1
fi

git checkout main 
git pull 
git checkout -
git rebase main 
ninja check-flang
