# This is a NixOS module:
{ config, lib, ... }:

let
  # wayland-info | grep wl_output -A2
  # niri msg outputs|grep Output
  monitors = {
    builtin = "eDP-1";
    home = "AOC Q27B3MA 17ZP7HA000040";
    work = "ASUSTek COMPUTER INC PA278QV S8LMQS000351";
  };
in
{
  config = lib.mkIf config.superkey.enable {
    home-manager.users.pjones =
      { config, ... }:
      {
        superkey.primaryOutput = monitors.builtin;

        wayland.windowManager.niri.settings = {
          output = [
            {
              _args = [ monitors.builtin ];
              mode = "2256x1504";
              scale = 1.4;

              layout = {
                # Smaller windows are hard to use:
                default-column-width.proportion = 0.5;
              };
            }
            {
              _args = [ monitors.work ];
              mode = "2560x1440@59.951";
              position._props = {
                x = 1611;
                y = 0;
              };
              scale = 1.0;
            }
            {
              _args = [ monitors.home ];
              mode = "2560x1440@59.951";
              position._props = {
                x = 1611;
                y = 0;
              };
              scale = 1.0;
            }
          ];
        };

        programs.waybar.settings.main = {
          # Additional outputs to put bars on to work around
          # https://github.com/Alexays/Waybar/issues/2061
          output = [
            monitors.work
            monitors.home
            "DP-3"
          ];
        };

        services.wpaperd.settings = {
          # Treat my main external monitor as a primary monitor:
          ${monitors.work}.path = config.superkey.wpaperd.primaryWallpaperDirectory;
          ${monitors.home}.path = config.superkey.wpaperd.primaryWallpaperDirectory;
          "DP-3".path = config.superkey.wpaperd.primaryWallpaperDirectory;
        };
      };
  };
}
