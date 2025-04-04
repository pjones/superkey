#!/bin/sh

# Wrapper around rofi:
exec @out@/bin/rofi-wrapper.sh \
  -show combi \
  -kb-accept-custom "" -kb-custom-1 "Control+Return" \
  "$@"
