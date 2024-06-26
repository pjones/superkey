# This is a NixOS module:
{ config, lib, ... }:

{
  config = lib.mkIf config.superkey.enable {
    home-manager.users.pjones = { config, ... }: {
      superkey.primaryOutput = "DP-1";

      wayland.windowManager.sway.config = {
        output."DP-1" = {
          mode = "2560x1440@59.9Hz";
          position = "0 0";
        };

        output."HDMI-A-1" = {
          mode = "2560x1440@59.95Hz";
          position = "2560 0";
        };
      };
    };
  };
}
