#!/usr/bin/env bash

################################################################################
# Force the current session to be locked even if the idle inhibitor
# would prevent it.
set -eu
set -o pipefail

# Tell swayidle to run all idle commands:
pkill -xu "$USER" -USR1 swayidle

# Release audio-based inhibitors:
systemctl --user restart wayland-pipewire-idle-inhibit.service

# FIXME: Should try to find a way to release the manual idle inhibitor
# that is part of waybar.
