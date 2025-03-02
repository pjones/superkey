{ config, lib, ... }:

let
  startCompositor =
    if config.superkey.compositor == "sway"
    then ''
      export COMPOSITOR_VERIFY_EXIT=1
      sway --validate
      sway && touch /tmp/compositor-exit-ok
    ''
    else if config.superkey.compositor == "niri"
    then ''
      export COMPOSITOR_VERIFY_EXIT=1
      niri-session && touch /tmp/compositor-exit-ok
    ''
    else ''
      echo >&2 "ERROR: Invalid compositor selected: ${config.superkey.compositor}"
      exit 1
    '';

  startCompositorFromShell = ''
    if [ -z "''${START_COMPOSITOR_FROM_SHELL:-}" ] && [ "$(tty)" = "/dev/tty1" ]; then
      export START_COMPOSITOR_FROM_SHELL=1
      ${startCompositor}
    fi
  '';
in
{
  config = {
    services.greetd.enable = lib.mkForce false;
    services.getty.autologinUser = lib.mkForce "pjones";
    programs.bash.loginShellInit = startCompositorFromShell;
    programs.zsh.loginShellInit = startCompositorFromShell;
  };
}
