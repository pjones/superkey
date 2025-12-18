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
      with_niri "current"
      ;;

    N)
      list_workspaces=0
      option_name=$OPTARG
      with_niri "new"
      ;;

    r)
      list_workspaces=0
      option_name=$OPTARG
      with_niri "rename"
      ;;

    s)
      list_workspaces=0
      option_name=$OPTARG
      with_niri "switch"
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [ "$list_workspaces" -eq 1 ]; then
    with_niri "all"
  fi
}

################################################################################
main "$@"
