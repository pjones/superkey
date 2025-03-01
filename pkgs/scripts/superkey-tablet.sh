#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_to_output=

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message
  -p      Map any tablets to the primary output
  -s      Map any tablets to the secondary output

EOF
}

################################################################################
map_to_output() {
  local output=$1

  case "$XDG_CURRENT_DESKTOP" in
  sway)
    local tool_id
    local other_monitor="eDP-1" # FIXME

    tool_id=$(
      swaymsg --type get_inputs |
        jq --raw-output '.[] | select(.type=="tablet_tool") | .identifier' |
        head -1
    )

    if [ "$output" = "secondary" ]; then
      other_monitor=$(
        swaymsg --type get_outputs |
          jq --raw-output "
            .[] |
            select(.active and .name != \"$other_monitor\") |
            .name
          " |
          head -1
      )
    fi

    if [ -n "$tool_id" ] && [ -n "$other_monitor" ]; then
      swaymsg --type command "input $tool_id map_to_output $other_monitor"
    fi
    ;;
  esac
}

################################################################################
parse_options() {
  # Option arguments are in $OPTARG
  while getopts "psh" o; do
    case "${o}" in
    h)
      usage
      exit
      ;;

    p)
      option_to_output=primary
      ;;

    s)
      option_to_output=secondary
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))
}

################################################################################
main() {
  parse_options "$@"

  if [ -n "$option_to_output" ]; then
    map_to_output "$option_to_output"
  fi
}

################################################################################
main "$@"
