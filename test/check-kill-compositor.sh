#!/usr/bin/env bash

set -eux
set -o pipefail

# Send all output to the systemd journal:
# exec > >(systemd-cat -t "$(basename "$0")" -p emerg) 2>&1

function wait_until_fails() {
  count=300

  while [ "$count" -gt 0 ]; do
    if ! eval "$*"; then
      break
    fi

    sleep 1
    count=$((count - 1))
  done
}

case "$XDG_CURRENT_DESKTOP" in
sway)
  test -L "$HOME/.config/sway/config"
  swaymsg -t command exit || :
  wait_until_fails pgrep -x sway

  if [ "${SWAY_VERIFY_EXIT:-0}" -eq 1 ]; then
    test -e /tmp/sway-exit-ok
  fi
  ;;
esac
