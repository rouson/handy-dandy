#!/bin/sh

if ! command -v brew ; then 
  echo "brew command not found. Doing nothing."
  exit 1
else
  # Uninstall all homebrew packages
  brew_list=`brew list`
  if [ ! -z "$brew_list" ]; then
    brew remove --force $brew_list
  fi
  # Uninstall all homebrew formulae
  brew_list_formula=`brew list --formula`
  if [ ! -z "$brew_list_formula" ]; then
    brew remove --cask --force $brew_list_formula
  fi
fi
