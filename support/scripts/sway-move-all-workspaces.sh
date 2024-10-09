#!/usr/bin/env bash

set -eu
set -o pipefail

for num in $(seq 1 10); do
  swaymsg -t command \
    "[workspace=$num] move workspace to output current" || :
done
