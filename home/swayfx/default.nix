{ config, lib, pkgs, ... }:

let
  cfg = config.superkey.swayfx;

in

{
  options.superkey.swayfx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.superkey.enable;
      description = "Enable SwayFX and related configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      package = pkgs.swayfx.override { isNixOS = true; };

      # Sway configuration that only SwayFX understands:
      extraConfig = ''
        corner_radius 8
        smart_corner_radius on
        shadows on
        default_dim_inactive 0.25
      '';
    };
  };
}
