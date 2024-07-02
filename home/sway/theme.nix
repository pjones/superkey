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
        for_window [app_id="firefox"] opacity set 0.95
        include ${config.superkey.theme}/theme/sway.cfg
      '';
    };
  };
}
