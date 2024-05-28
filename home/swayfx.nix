{ lib, pkgs, config, ... }:

let
  cfg = config.programs.pjones.swayfx;
  mod = config.wayland.windowManager.sway.config.modifier;
in
{
  options.programs.pjones.swayfx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable SwayFX and configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;
      package = pkgs.swayfx.override { isNixOS = true; };
      config.modifier = "Mod4";
      config.keybindings = {
        "${mod}+e" = "exec emacs";
      };
    };
  };
}
