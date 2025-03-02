#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
niri_workspace_id() {
  niri msg --json workspaces |
    jq --raw-output '
        .[] |
        select(.is_focused) |
        .id'
}

################################################################################
main() {
  case "${XDG_CURRENT_DESKTOP:-}" in
  niri)
    local workspace_left_id
    local workspace_right_id

    niri msg action focus-monitor-right
    workspace_right_id=$(niri_workspace_id)

    niri msg action focus-monitor-left
    workspace_left_id=$(niri_workspace_id)

    niri msg action move-workspace-to-monitor-right
    niri msg action focus-monitor-right
    niri msg action focus-workspace "$workspace_right_id"
    niri msg action move-workspace-to-monitor-left
    niri msg action focus-workspace "$workspace_left_id"
    niri msg action focus-monitor-left
    niri msg action focus-workspace "$workspace_right_id"
    ;;

  sway)
    swaymsg --type command "
      focus output right;
      move workspace to output left;
      workspace back_and_forth;
      move workspace to output right;
      focus output right"
    ;;
  esac
}

################################################################################
main "$@"
