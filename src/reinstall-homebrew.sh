#!/bin/sh

if command -v brew ; then 
  uninstall-homebrew-packages.sh
fi
install-homebrew.sh
