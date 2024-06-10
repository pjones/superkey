{ lib, pkgs, config, ... }:

let
  cfg = config.superkey.sway;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        gaps.inner = 5;
        gaps.smartGaps = true;
        gaps.smartBorders = "on";
      };

      extraConfig = ''
        include ${config.superkey.theme}/sway/sway.cfg
      '';
    };
  };
}
