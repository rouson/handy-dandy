#!/bin/sh

if command -v brew ; then 
  uninstall-homebrew-packages.sh
  uninstall-homebrew.sh
fi
install-homebrew.sh
