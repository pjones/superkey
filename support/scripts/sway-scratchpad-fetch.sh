#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options] char

  -h      This message

Bring forward the scratchpad window marked with the given chracter.

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

  if [ $# -eq 1 ]; then
    char=$1
  else
    echo >&2 "ERROR: missing marker character"
    exit 1
  fi

  local workspace
  workspace=$(desktop-workspace -n | cut -d: -f1)

  swaymsg -t command \
    "[con_mark=\"S$char\"] scratchpad show;
     mark --add SL$workspace"
}

################################################################################
main "$@"
