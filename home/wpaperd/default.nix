{ config, lib, pkgs, ... }:

let
  cfg = config.superkey;

  # https://www.reddit.com/r/wallpapers/comments/ge4hrd/geometry/
  defaultImage = pkgs.fetchurl {
    url = "https://i.redd.it/tg9ac8kn10x41.jpg";
    sha256 = "0pb32hzrngl06c1icb2hmdq8ja7v1gc2m4ss32ihp6rk45c59lji";
  };

  setDefaultImage = pkgs.writeShellApplication {
    name = "set-default-wallpaper";
    runtimeInputs = [ pkgs.swaybg ];
    text = ''
      if [ ! -d "${cfg.wpaperd.primaryWallpaperDirectory}" ]; then
        exec swaybg --output "${cfg.primaryOutput}" --image ${defaultImage} --mode fill
      fi
    '';
  };
in
{
  options.superkey.wpaperd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = "Automatically change wallpapers.";
    };

    primaryWallpaperDirectory = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/documents/pictures/backgrounds/primary";
      description = "Directory of images to display on the primary output";
    };

    secondaryWallpaperDirectory = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/documents/pictures/backgrounds/secondary";
      description = "Directory of images to display on secondary outputs";
    };
  };

  config = lib.mkIf cfg.wpaperd.enable {
    wayland.windowManager.sway.extraConfig = ''
      exec ${setDefaultImage}/bin/set-default-wallpaper
    '';

    programs.wpaperd = {
      enable = true;

      settings = {
        default = {
          duration = "1h";
          sorting = "random";
          mode = "center";
          transition_time = 600;
          queue_size = 10;
        };

        any.path = cfg.wpaperd.secondaryWallpaperDirectory;
        ${cfg.primaryOutput}.path = cfg.wpaperd.primaryWallpaperDirectory;
      };
    };

    systemd.user.services.wpaperd = {
      Unit = {
        Description = "Wallpaper Daemon";
        Documentation = "https://github.com/danyspin97/wpaperd";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session-pre.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
        ConditionDirectoryNotEmpty = cfg.wpaperd.primaryWallpaperDirectory;
      };

      Service = {
        ExecStartPre = toString (pkgs.writeShellScript "kill-swaybg" ''
          ${pkgs.procps}/bin/pkill -u "$USER" swaybg || true
        '');
        ExecStart = "${config.programs.wpaperd.package}/bin/wpaperd";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
