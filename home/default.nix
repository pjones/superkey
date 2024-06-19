{ config, lib, pkgs, ... }:
{
  imports = [
    ./clipboard
    ./screenshot
    ./sway
    ./swayfx
    ./swaylock
    ./swaync
    ./waybar
    ./wpaperd
  ];

  options.superkey = {
    enable = lib.mkEnableOption "Enable Wayland configuration.";

    theme = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = "A theme package.";
    };

    primaryOutput = lib.mkOption {
      type = lib.types.str;
      description = ''
        The name of the primary output (display), For example: eDP-1.
      '';
    };
  };

  config = lib.mkIf config.superkey.enable {
    home.packages = with pkgs; [
      jq # A lightweight and flexible command-line JSON processor
      libnotify # A library that sends desktop notifications to a notification daemon
      pjones.desktop-scripts # Scripts for Xorg and Wayland.
      pjones.rofirc-wayland # Rofi launcher
      wayland-utils # Wayland utilities (wayland-info)
      wev # Wayland event viewer
      wl-clipboard # Command-line copy/paste utilities for Wayland
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
      configPackages = [ config.wayland.windowManager.sway.package ];
      config = {
        sway.default = [ "wlr" "gtk" ];
        common.default = [ "gtk" ];
      };
    };
  };
}
