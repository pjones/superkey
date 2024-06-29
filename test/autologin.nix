{ lib, ... }:

let
  startSway = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      sway --validate
      sway && touch /tmp/sway-exit-ok
    fi
  '';
in
{
  config = {
    services.greetd.enable = lib.mkForce false;
    services.getty.autologinUser = "pjones";
    programs.bash.loginShellInit = startSway;
    programs.zsh.loginShellInit = startSway;
  };
}
