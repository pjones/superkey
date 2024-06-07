{ lib, pkgs, config, ... }:

let
  cfg = config.waynix.sway;
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
        include ${config.waynix.theme}/sway/sway.cfg
      '';
    };
  };
}
