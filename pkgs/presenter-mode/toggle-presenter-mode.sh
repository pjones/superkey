#!/usr/bin/env bash

set -eu
set -o pipefail

################################################################################
_gsettings() {
  local command=$1
  shift

  gsettings --schemadir @schema_dir@ \
    "$command" com.freerangebits.desktop.presenter-mode \
    "$@"
}

################################################################################
get_val() {
  _gsettings get "$@"
}

################################################################################
set_val() {
  _gsettings set "$@" >/dev/null 2>&1
}

################################################################################
toggle_dnd() {
  local enabled=$1
  local options=()

  if [ "$enabled" = "false" ]; then
    options+=("--dnd-on")
  else
    options+=("--dnd-off")
  fi

  swaync-client "${options[@]}" >/dev/null 2>&1
}

################################################################################
toggle_inhibit() {
  local enabled=$1
  local con_id=$2
  local state="none"

  if [ "$enabled" = "false" ]; then
    state="open"
  fi

  if [ -n "$con_id" ] && [ "$con_id" != 0 ]; then
    swaymsg --type command "[con_id=$con_id] inhibit_idle $state"
  fi
}

################################################################################
toggle_tablet_tool() {
  local enabled=$1
  local tool_id
  local other_monitor="*"

  tool_id=$(
    swaymsg --type get_inputs |
      jq --raw-output '.[] | select(.type=="tablet_tool") | .identifier' |
      head -1
  )

  if [ "$enabled" = "false" ]; then
    other_monitor=$(
      swaymsg --type get_outputs |
        jq --raw-output '.[] | select(.active and .name != "eDP-1") | .name' |
        head -1
    )
  fi

  if [ -n "$tool_id" ] && [ -n "$other_monitor" ]; then
    swaymsg --type command "input $tool_id map_to_output $other_monitor"
  fi
}

################################################################################
main() {
  local state=false
  local con_id=0

  state=$(get_val enabled)

  if [ "$state" = "false" ]; then
    con_id=$(
      swaymsg --type get_tree |
        jq '.. | select(.type?) | select(.focused==true) | .id' || :
    )

    set_val enabled true
    set_val con-id "$con_id"
    toggle_dnd "$state"
    toggle_inhibit "$state" "$con_id"
    toggle_tablet_tool "$state"
  else
    con_id=$(get_val con-id)
    set_val enabled false
    set_val con-id 0
    toggle_dnd "$state"
    toggle_inhibit "$state" "$con_id"
    toggle_tablet_tool "$state"
  fi
}

################################################################################
main "$@"
