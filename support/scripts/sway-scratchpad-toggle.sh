#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message

Toggle the most recently seen scratchpad on this workspace.
EOF
}

################################################################################
main() {
  # Option arguments are in $OPTARG
  while getopts "h" o; do
    case "${o}" in
    h)
      usage
      exit
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  local workspace
  workspace=$(desktop-workspace -n | cut -d: -f1)
  swaymsg -t command "[con_mark=\"SL$workspace\"] scratchpad show"
}

################################################################################
main
