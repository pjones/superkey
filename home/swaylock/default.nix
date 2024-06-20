{ config, lib, pkgs, ... }:

let
  cfg = config.superkey.swaylock;
  colors = config.superkey.theme.colors;

  lockTimeout = cfg.lockAfterMin * 60;
  secureTimeout = cfg.secureAfterMin * 60;
  blankTimeout = lockTimeout + 60;

  # Format a color for swaylock:
  color = str: alpha: builtins.substring 1 (builtins.stringLength str - 1) str + alpha;

  # Path to tools we need:
  swaymsg = "${config.wayland.windowManager.sway.package}/bin/swaymsg";
  desktop-pre-suspend = "${pkgs.pjones.desktop-scripts}/bin/desktop-pre-suspend";

  # Script that locks the screen after finding a suitable background
  # image.
  lockCmd = pkgs.writeShellApplication {
    name = "lock";
    runtimeInputs = [
      pkgs.pjones.desktop-scripts
      config.programs.swaylock.package
    ];
    text = ''
      # Ensure swaylock *always* starts:
      trap "exec swaylock -f" ERR

      default_lock_image=${../../support/images/lock.png}
      args=("-f")

      if [ -d "${cfg.imagePath}" ]; then
        image=$(desktop-random-file -i -d "${cfg.imagePath}" -D "$default_lock_image")
        args+=("--image" "$image")
      elif [ -e "${cfg.imagePath}" ]; then
        args+=("--image" "${cfg.imagePath}")
      else
        args+=("--image" "$default_lock_image")
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
        minutes of being idle.
      '';
    };

    secureAfterMin = lib.mkOption {
      type = lib.types.int;
      default = 120;
      description = ''
        Automatically remove SSH/GPG keys after this many minutes of
        being idle.
      '';
    };

    imagePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/documents/pictures/backgrounds/lock-screen";
      description = ''
        Path to the image or directory of images to use for the lock
        screen.
      '';
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
        font = "Hermit";
        font-size = "24";
        color = "000000FF";
        bs-hl-color = color colors.comment "AA";
        caps-lock-key-hl-color = color colors.red "FF";
        inside-color = color colors.background "AA";
        inside-clear-color = color colors.background "AA";
        inside-caps-lock-color = color colors.red "FF";
        inside-ver-color = color colors.purple "AA";
        inside-wrong-color = color colors.orange "AA";
        key-hl-color = color colors.green "AA";
        layout-text-color = color colors.foreground "FF";
        layout-bg-color = "00000000";
        layout-border-color = "00000000";
        text-color = color colors.foreground "FF";
        text-caps-lock-color = color colors.foreground "FF";
        text-ver-color = color colors.foreground "FF";
        text-wrong-color = color colors.background "FF";
        line-color = color colors.background "FF";
        line-clear-color = color colors.background "FF";
        line-caps-lock-color = color colors.background "FF";
        line-ver-color = color colors.background "FF";
        line-wrong-color = color colors.background "FF";
        ring-color = color colors.background "AA";
        ring-clear-color = "00000000";
        ring-caps-lock-color = color colors.red "FF";
        ring-ver-color = color colors.purple "AA";
        ring-wrong-color = color colors.orange "AA";
        separator-color = color colors.background "FF";
      };
    };

    services.swayidle = {
      enable = true;
      extraArgs = [ "-w" ];

      timeouts = [
        { timeout = lockTimeout; command = "loginctl lock-session"; }
        { timeout = secureTimeout; command = desktop-pre-suspend; }
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
