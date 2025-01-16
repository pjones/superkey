#!/usr/bin/env bash

set -eux
set -o pipefail

swaymsg -t command rename workspace to 1:Hacking
swaymsg -t command layout splitv
swaymsg -t command gaps outer all set 100

# Verify that the `e' script can connect to the daemon:
test "$(e -d -- --eval nil)" = "nil"

# Work around a long standing bug in my Emacs configuration where
# my `eterm' script can't open a window if the terminal window would
# be the first one loaded by the daemon.
e -c '/etc/issue'
swaymsg -t command kill
eterm -e fastfetch
