#!/usr/bin/env bash

set -eux
set -o pipefail

swaymsg -t command rename workspace to 1:Hacking
swaymsg -t command layout splitv
swaymsg -t command gaps outer all set 100
eterm -e fastfetch
