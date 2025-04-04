#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
# Options set from the command line.
option_name= # The name of a workspace to act on.

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message
  -n      Print the name of the current workspace
  -N NAME Create a new workspace named NAME
  -r NAME Rename current workspace to NAME
  -s NAME Switch to workspace NAME

If no options are given, prints a list of all workspace names.

EOF
}

################################################################################
function with_sway() {
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
    swaymsg --type command workspace number "$option_name"
    ;;

  *)
    echo >&2 "ERROR: sway does not support workspace $command"
    exit 1
    ;;
  esac
}

################################################################################
function with_niri() {
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
    niri msg action focus-workspace "$option_name"
    ;;

  new)
    niri msg action focus-workspace 255
    niri msg action set-workspace-name "$option_name"
    ;;

  rename)
    if [ -z "$option_name" ]; then
      niri msg action unset-workspace-name
    else
      niri msg action set-workspace-name "$option_name"
    fi
    ;;
  esac
}

################################################################################
function with_wmctrl() {
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
    desktop_id=$(echo "$option_name" | cut -d: -f2)
    [ -z "$desktop_id" ] && exit
    wmctrl -s "$((desktop_id - 1))"
    ;;

  *)
    echo >&2 "ERROR: wmctrl does not support workspace $command"
    exit 1
    ;;
  esac
}

################################################################################
function dispatch() {
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
function main() {
  local list_workspaces=1

  while getopts "hN:r:ns:" o; do
    case "${o}" in
    h)
      usage
      exit
      ;;

    n)
      list_workspaces=0
      dispatch "current"
      ;;

    N)
      list_workspaces=0
      option_name=$OPTARG
      dispatch "new"
      ;;

    r)
      list_workspaces=0
      option_name=$OPTARG
      dispatch "rename"
      ;;

    s)
      list_workspaces=0
      option_name=$OPTARG
      dispatch "switch"
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [ "$list_workspaces" -eq 1 ]; then
    dispatch "all"
  fi
}

################################################################################
main "$@"
