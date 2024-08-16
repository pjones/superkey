# This is a NixOS module:
{ config, lib, ... }:

let
  external = "Samsung Electric Company S32D850 0x304C3341";
in
{
  config = lib.mkIf config.superkey.enable {
    home-manager.users.pjones = { config, ... }: {
      superkey.primaryOutput = "eDP-1";

      wayland.windowManager.sway.config = {
        output."eDP-1" = {
          mode = "2256x1504";
          scale = "1.4";
        };

        output.${external} = {
          mode = "2560x1440@59.951Hz";
          pos = "1611 0";
          scale = "1.0";
        };
      };

      programs.waybar.settings.main = {
        # Additional outputs to put bars on to work around
        # https://github.com/Alexays/Waybar/issues/2061
        output = [ external ];
      };

      programs.wpaperd.settings = {
        # Treat my main external monitor as a primary monitor:
        ${external}.path =
          config.superkey.wpaperd.primaryWallpaperDirectory;
      };
    };
  };
}
