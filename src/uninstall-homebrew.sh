#!/bin/sh

if ! command -v brew ; then 
  echo "brew command not found. Doing nothing."
  exit 1
else
  uninstall-homebrew-packages.sh

  # Uninstall homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
fi
