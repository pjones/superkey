{ lib, pkgs, config, ... }:

let
  cfg = config.superkey.sway;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        gaps.inner = 5;
        gaps.outer = 20;
        gaps.smartBorders = "off";
      };

      extraConfig = ''
        smart_gaps inverse_outer # Home Manager module broken.
        include ${config.superkey.theme}/sway/sway.cfg
      '';
    };
  };
}
