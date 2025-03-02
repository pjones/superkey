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
with_sway() {
  local command=$1

  case "$command" in
  current)
    swaymsg --raw --type get_workspaces |
      jq --raw-output '.[] | select(.focused) | .name' |
      head -n1
    ;;

  all)
    swaymsg --raw --type get_workspaces |
      jq --raw-output '.[] | .name'
    ;;

  switch)
    swaymsg --type command workspace number "$option_switch_to"
    ;;
  esac
}

################################################################################
with_niri() {
  local command=$1

  case "$command" in
  current)
    niri msg --json workspaces |
      jq --raw-output '
        .[] |
        select(.is_focused) |
        if .name
        then .name
        else .id
        end'
    ;;

  all)
    niri msg --json workspaces |
      jq --raw-output '.[] | if .name then .name else .id end'
    ;;

  switch)
    niri msg action focus-workspace "$option_switch_to"
    ;;
  esac
}

################################################################################
with_wmctrl() {
  local command=$1
  local desktop_id

  case "$command" in
  current)
    wmctrl -d |
      awk '$2 == "*" {
      for (i=($8 == "N/A" ? 9 : 10); i<=NF; i++) {
        printf("%s%s", $i, i<NF ? OFS : "\n")
      }
    }'
    ;;

  all)
    wmctrl -d |
      awk '{
      for (i=($8 == "N/A" ? 9 : 10); i<=NF; i++) {
        printf("%s:%d%s", $i, $1 + 1, i<NF ? OFS : "\n")
      }
    }'
    ;;

  switch)
    desktop_id=$(echo "$option_switch_to" | cut -d: -f2)
    [ -z "$desktop_id" ] && exit
    wmctrl -s "$((desktop_id - 1))"
    ;;
  esac
}

################################################################################
dispatch() {
  local command=$1

  case "${XDG_CURRENT_DESKTOP:-}" in
  niri)
    with_niri "$command"
    ;;

  sway)
    with_sway "$command"
    ;;

  *)
    with_wmctrl "$command"
    ;;
  esac
}

################################################################################
main() {
  if [ "$option_current_name" -eq 1 ]; then
    dispatch "current"
  elif [ -n "$option_switch_to" ]; then
    dispatch "switch"
  else
    dispatch "all"
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
