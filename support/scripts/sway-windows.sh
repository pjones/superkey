#!/usr/bin/env bash

set -eu
set -o pipefail

swaymsg -t get_tree |
  jq --raw-output "$@" \
    '[recurse(.nodes[], .floating_nodes[])]
     | map(select(.name))
     | map(.name)
     | join("\n")'
