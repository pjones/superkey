{ lib, pkgs, config, ... }:

let
  cfg = config.waynix.sway;
in
{
  imports = [
    ./keys.nix
    ./theme.nix
  ];

  options.waynix.sway = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.waynix.enable;
      description = "Enable Sway and related configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.sway-overfocus
    ];

    wayland.windowManager.sway = {
      enable = true;
      checkConfig = false; # Currently broken

      config = {
        bars = [ ];

        workspaceLayout = "default";

        focus.followMouse = "yes";
        focus.newWindow = "smart";
        focus.wrapping = "yes";
        focus.mouseWarping = "output";
      };

      extraConfig = ''
        default_orientation auto
        force_display_urgency_hint 1000
        popup_during_fullscreen smart
      '';
    };
  };
}
