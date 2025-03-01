{ config, lib, pkgs, ... }:

{
  imports = [
    ./clipboard
    ./inhibit
    ./screenshot
    ./sway
    ./swayfx
    ./swaylock
    ./swaync
    ./theme.nix
    ./waybar
    ./wpaperd
  ];

  options.superkey = {
    enable = lib.mkEnableOption "Enable Wayland configuration.";

    compositor = lib.mkOption {
      type = lib.types.enum [ "sway" ];
      default = "sway";
      description = "The name of the compositor to use";
    };

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
      helvum # A GTK patchbay for pipewire
      jq # A lightweight and flexible command-line JSON processor
      libnotify # A library that sends desktop notifications to a notification daemon
      networkmanagerapplet # NetworkManager control applet for GNOME
      nwg-displays # Output management utility for Sway
      pjones.presenter-mode # Toggle presenter mode.
      pjones.rofirc-wayland # Rofi launcher
      pjones.superkey-scripts # Wayland scripts.
      wayland-utils # Wayland utilities (wayland-info)
      wev # Wayland event viewer
      wl-clipboard # Command-line copy/paste utilities for Wayland
    ];

    # This uses `xsession` but it's needed for Wayland too:
    xsession.preferStatusNotifierItems = true;

    # Tray icon for network connections:
    services.network-manager-applet.enable = true;

    # Tray icon for disks:
    services.udiskie = {
      enable = true;
      automount = false;
    };

    # Set XDG user directories:
    xdg.userDirs = {
      enable = true;
      createDirectories = false;

      desktop = "$HOME/desktop";
      documents = "$HOME/documents";
      download = "$HOME/download";
      music = "$HOME/documents/music";
      pictures = "$HOME/documents/pictures";
      publicShare = "$HOME/public";
      templates = "$HOME/documents/templates";
      videos = "$HOME/documents/videos";
    };

    # Application menu items:
    xdg.desktopEntries = {
      sleep-system = {
        name = "Sleep";
        exec = "systemctl suspend-then-hibernate";
        icon = "emblem-system";
        terminal = false;
        categories = [ "System" ];
      };
    };

    # For apps that want a user picture like GDM:
    home.file.".face".source = "${pkgs.pjones.avatar}/share/faces/pjones.jpg";
  };
}
