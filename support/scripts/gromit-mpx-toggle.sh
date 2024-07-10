#!/usr/bin/env bash

set -eu
set -o pipefail

if pgrep --euid "$USER" gromit-mpx-; then
  systemctl --user stop gromit-mpx.service
else
  systemctl --user start gromit-mpx.service
fi
