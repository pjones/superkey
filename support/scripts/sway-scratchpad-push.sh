#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options] char

  -h      This message

Move the focused window into the scratchpad and mark it with the given
chracter.
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
    "mark --add S$char;
     mark --add SL$workspace;
     move window to scratchpad"
}

################################################################################
main "$@"
