#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
# Options set from the command line.
option_current_name=0
option_switch_to=

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message
  -n      Print the name of the current workspace
  -s NAME Switch to workspace NAME

If no options are given, prints a list of all workspace names.

EOF
}

################################################################################
sway_current_workspace() {
  swaymsg --raw --type get_workspaces |
    jq --raw-output '.[] | select(.focused) | .name' |
    head -n1
}

################################################################################
sway_all_workspaces() {
  swaymsg --raw --type get_workspaces |
    jq --raw-output '.[] | .name'
}

################################################################################
sway_switch_workspace() {
  swaymsg --type command workspace number "$option_switch_to"
}

################################################################################
wmctrl_current_workspace() {
  wmctrl -d |
    awk '$2 == "*" {
      for (i=($8 == "N/A" ? 9 : 10); i<=NF; i++) {
        printf("%s%s", $i, i<NF ? OFS : "\n")
      }
    }'
}

################################################################################
wmctrl_all_workspaces() {
  wmctrl -d |
    awk '{
      for (i=($8 == "N/A" ? 9 : 10); i<=NF; i++) {
        printf("%s:%d%s", $i, $1 + 1, i<NF ? OFS : "\n")
      }
    }'
}

################################################################################
wmctrl_switch_workspace() {
  desktop_id=$(echo "$option_switch_to" | cut -d: -f2)
  [ -z "$desktop_id" ] && exit
  wmctrl -s "$((desktop_id - 1))"
}

################################################################################
dispatch() {
  local suffix=$1

  if [ -n "${SWAYSOCK:-}" ]; then
    eval "sway_$suffix"
  elif [ -n "${DISPLAY:-}" ] && type wmctrl &>/dev/null; then
    eval "wmctrl_$suffix"
  else
    echo >&2 "ERROR: I don't know this compositor or window manager."
    exit 1
  fi
}

################################################################################
main() {
  if [ "$option_current_name" -eq 1 ]; then
    dispatch "current_workspace"
  elif [ -n "$option_switch_to" ]; then
    dispatch "switch_workspace"
  else
    dispatch "all_workspaces"
  fi
}

################################################################################
while getopts "hns:" o; do
  case "${o}" in
  h)
    usage
    exit
    ;;

  n)
    option_current_name=1
    ;;

  s)
    option_switch_to=$OPTARG
    ;;

  *)
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))
main "$@"
