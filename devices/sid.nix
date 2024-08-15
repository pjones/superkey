# This is a NixOS module:
{ config, lib, ... }:

{
  config = lib.mkIf config.superkey.enable {
    home-manager.users.pjones = { config, ... }: {
      superkey.primaryOutput = "eDP-1";

      wayland.windowManager.sway.config = {
        output."eDP-1" = {
          mode = "2256x1504";
          scale = "1.4";
        };

        output."Samsung Electric Company S32D850 0x304C3341" = {
          mode = "2560x1440@59.951Hz";
          pos = "1611 0";
          scale = "1.0";
        };
      };

      programs.waybar.settings.main = {
        # Additional outputs to put bars on to work around
        # https://github.com/Alexays/Waybar/issues/2061
        output = [
          "Samsung Electric Company S32D850 0x304C3341"
        ];
      };
    };
  };
}
