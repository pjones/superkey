#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message

Remove the currently focused floaing window from the scratchpad.
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

  # Find all of the scratchpad-related marks:
  mapfile -t marks < <(
    swaymsg -rt get_tree |
      jq --raw-output \
        'recurse(.nodes[]) |
        .floating_nodes[] |
        select(.focused) |
        .marks[] |
        select(test("^S"))'
  )

  # Remove those marks:
  for mark in "${marks[@]}"; do
    swaymsg -t command "unmark $mark"
  done

  # Now pull the window out of the scratchpad:
  swaymsg -t command "floating disable"
}

################################################################################
main "$@"
