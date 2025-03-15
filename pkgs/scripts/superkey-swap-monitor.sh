#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
niri_workspace_id() {
  local output=$1

  niri msg --json workspaces |
    jq \
      --raw-output \
      --arg output "$output" \
      'map(select(.is_active and .output == $output)) | .[] | .id'
}

################################################################################
niri_worspace_to_output() {
  local id=$1
  local output=$2

  nc -U "$NIRI_SOCKET" <<ACTION
{"Action":{"MoveWorkspaceToMonitor":{"output":"$output","reference":{"Id":$id}}}}
ACTION

  nc -U "$NIRI_SOCKET" <<ACTION
{"Action":{"FocusWorkspace":{"reference":{"Id":$id}}}}
ACTION
}

################################################################################
main() {
  case "${XDG_CURRENT_DESKTOP:-}" in
  niri)
    local focused_output
    local other_output
    local workspace_focused_id
    local workspace_other_id

    focused_output=$(
      niri msg --json focused-output |
        jq --raw-output .name
    )

    other_output=$(
      niri msg --json outputs |
        jq \
          --raw-output \
          --arg skip "$focused_output" \
          'map(select(.name != $skip)) | .[] | .name' |
        head -1
    )

    workspace_focused_id=$(niri_workspace_id "$focused_output")
    workspace_other_id=$(niri_workspace_id "$other_output")

    niri msg action do-screen-transition --delay-ms 150
    niri_worspace_to_output "$workspace_focused_id" "$other_output"
    niri_worspace_to_output "$workspace_other_id" "$focused_output"
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
