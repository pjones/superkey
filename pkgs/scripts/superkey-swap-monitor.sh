#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
main() {
  case "${XDG_CURRENT_DESKTOP:-}" in
  niri)
    niri msg action do-screen-transition --delay-ms 150
    niri msg action move-workspace-to-monitor-next
    niri msg action focus-workspace-previous
    niri msg action move-workspace-to-monitor-previous
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
