{ lib, ... }:

let
  startCompositor = ''
    export COMPOSITOR_VERIFY_EXIT=1
    niri-session && touch /tmp/compositor-exit-ok
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
