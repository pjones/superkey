#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
color_scheme=
gtk_theme=

################################################################################
case "${1:-dark}" in
dark)
  color_scheme=prefer-dark
  gtk_theme=Adwaita-dark
  ;;

light)
  color_scheme=prefer-light
  gtk_theme=Adwaita
  ;;

*)
  echo >&2 "ERROR: theme name should be dark or light"
  exit 1
  ;;
esac

################################################################################
gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
