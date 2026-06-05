{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.superkey;
in
{
  imports = [
    ./inhibit
    ./hyprlock.nix
    ./lock.nix
    ./niri
    ./swaync
    ./theme.nix
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
      ghostty # Fast, native, feature-rich terminal emulator pushing modern features
      jq # A lightweight and flexible command-line JSON processor
      libnotify # A library that sends desktop notifications to a notification daemon
      nautilus # File manager for GNOME
      networkmanagerapplet # NetworkManager control applet for GNOME
      nwg-displays # Output management utility for Sway and Hyprland
      pamixer # Pulseaudio command line mixer
      pjones.presenter-mode # Toggle presenter mode.
      pjones.rofirc # Rofi launcher configuration
      pjones.superkey-scripts # Wayland scripts.
      playerctl # Command-line utility for controlling media players
      rofi # Window switcher, run dialog and dmenu replacement for Wayland
      sushi # Quick previewer for Nautilus
      wayland-utils # Wayland utilities (wayland-info)
      wev # Wayland event viewer
      wl-clipboard # Command-line copy/paste utilities for Wayland
      wl-mirror # Simple Wayland output mirror client
      wtype # xdotool type for wayland
    ];

    # Ensure the xsession is disabled so Home Manager will enable
    # Wayland settings:
    xsession.enable = lib.mkForce false;

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
      setSessionVariables = true;

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

      mirror-output = {
        name = "Mirror Next Output";
        exec = "superkey-mirror.sh";
        icon = "emblem-system";
        terminal = false;
        categories = [ "System" ];
      };
    };

    # For apps that want a user picture like GDM:
    home.file.".face".source = "${pkgs.pjones.avatar}/share/faces/pjones.jpg";
  };
}
