{ lib, pkgs, config, ... }:

let
  cfg = config.programs.pjones.swayfx;
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
        corner_radius 8
        smart_corner_radius on
        shadows on
        default_dim_inactive 0.25
      '';
    };
  };
}
