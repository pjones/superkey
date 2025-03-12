{ config, lib, pkgs, ... }:

let
  cfg = config.superkey;
in
{
  imports = [
    ./inhibit
    ./niri
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
      type = lib.types.enum [ "niri" "sway" ];
      default = "sway";
      description = "The name of the compositor to use";
    };

    theme = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = "A theme package.";
    };

    workspaceNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "Tasks" # 1
        "Social" # 2
        "Hacking" # 3
        "Media" # 4
        "Meetings" # 5
        "Papers" # 6
        "Study" # 7
        "Work" # 8
        "Spare" # 9
        "Web" # 10
      ];
      description = "Workspace names";
    };

    primaryOutput = lib.mkOption {
      type = lib.types.str;
      description = ''
        The name of the primary output (display), For example: eDP-1.
      '';
    };

    commands = {
      sendClipboard = lib.mkOption {
        type = lib.types.str;
        default = "kdeconnect-cli -n Chet --send-clipboard";
        description = "Shell command to send the clipboard to another device";
      };

      extraSessionCommands = lib.mkOption {
        type = lib.types.lines;
        default = ''
          export _JAVA_AWT_WM_NONREPARENTING=1
          export NIXOS_OZONE_WL=1
          export QT_QPA_PLATFORM=wayland
          export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
          export SDL_VIDEODRIVER=wayland
        '';
        description = ''
          Shell commands executed just before the compositor is started.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      brightnessctl # This program allows you read and control device brightness
      helvum # A GTK patchbay for pipewire
      jq # A lightweight and flexible command-line JSON processor
      libnotify # A library that sends desktop notifications to a notification daemon
      networkmanagerapplet # NetworkManager control applet for GNOME
      nwg-displays # Output management utility for Sway
      pamixer # Pulseaudio command line mixer
      pjones.presenter-mode # Toggle presenter mode.
      pjones.rofirc-wayland # Rofi launcher
      pjones.superkey-scripts # Wayland scripts.
      playerctl # Command-line utility for controlling media players
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
