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
      };

      programs.waybar.settings.main = {
        height = 20;
        name = "hidpi";
      };
    };
  };
}
