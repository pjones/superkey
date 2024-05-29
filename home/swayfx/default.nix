{ lib, pkgs, config, ... }:

let
  cfg = config.programs.pjones.swayfx;
in
{
  imports = [
    ./keys.nix
  ];

  options.programs.pjones.swayfx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable SwayFX and configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.wayland-utils
      pkgs.wev
    ];

    wayland.windowManager.sway = {
      enable = true;
      package = pkgs.swayfx.override { isNixOS = true; };
      checkConfig = false; # Currently broken

      config = {
        workspaceLayout = "default";

        focus.followMouse = "yes";
        focus.newWindow = "smart";
        focus.wrapping = "yes";
        focus.mouseWarping = "output";
      };

      extraConfig = ''
        default_orientation auto
        force_display_urgency_hint 1000
        smart_borders on
        smart_gaps on
        popup_during_fullscreen smart
      '';
    };
  };
}
