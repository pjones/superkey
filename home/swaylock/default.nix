{ config, lib, pkgs, ... }:

let
  cfg = config.superkey.swaylock;

  lockTimeout = cfg.lockAfterMin * 60;
  blankTimeout = lockTimeout + 60;

  swaymsg = "${config.wayland.windowManager.sway.package}/bin/swaymsg";

  # Script that locks the screen after finding a suitable background
  # image.
  lockCmd = pkgs.writeShellApplication {
    name = "lock";
    runtimeInputs = [ config.programs.swaylock.package ];
    text = ''
      args=("-f")

      if [ -e "${cfg.imagePath}" ]; then
        args+=("--image" "${cfg.imagePath}")
      else
        args+=("--image" "${../../support/images/lock.png}")
      fi

      exec swaylock "''${args[@]}"
    '';
  };
in
{
  options.superkey.swaylock = {
    lockAfterMin = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = ''
        Automatically lock the screen after the given number of
        minutes.
      '';
    };

    imagePath = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.lock-screen";
      description = "Path to the image to use for the lock screen.";
    };
  };

  config = lib.mkIf config.superkey.enable {
    programs.swaylock = {
      enable = true;
      settings = {
        ignore-empty-password = true;
        show-failed-attempts = true;
        indicator-caps-lock = true;
        scaling = "fit";
        indicator-radius = 200;
        color = "000000FF";
      };
    };

    services.swayidle = {
      enable = true;
      extraArgs = [ "-w" ];

      timeouts = [
        { timeout = lockTimeout; command = "loginctl lock-session"; }
        {
          timeout = blankTimeout;
          command = "${swaymsg} 'output * power off'";
          resumeCommand = "${swaymsg} 'output * power on'";
        }
      ];
    };

    systemd.user.services.screen-lock = {
      # The targets used here are created by the NixOS setting:
      # services.systemd-lock-handler.
      Unit = {
        Description = "Screen locker for Wayland";
        Documentation = [ "man:swaylock(1)" ];
        PartOf = [ "lock.target" ];
        OnSuccess = [ "unlock.target" ];
        Before = [ "lock.target" ];
      };

      Service = {
        Type = "forking";
        ExecStart = "${lockCmd}/bin/lock";
        Restart = "on-failure";
        RestartSec = 0;
      };

      Install = {
        WantedBy = [ "lock.target" ];
      };
    };
  };
}
