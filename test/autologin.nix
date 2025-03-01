{ config, lib, ... }:

let
  startCompositor =
    if config.superkey.compositor == "sway"
    then ''
      export SWAY_VERIFY_EXIT=1
      sway --validate
      sway && touch /tmp/sway-exit-ok
    ''
    else ":";

  startCompositorFromShell = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      ${startCompositor}
    fi
  '';
in
{
  config = {
    services.greetd.enable = lib.mkForce false;
    services.getty.autologinUser = "pjones";
    programs.bash.loginShellInit = startCompositorFromShell;
    programs.zsh.loginShellInit = startCompositorFromShell;
  };
}
