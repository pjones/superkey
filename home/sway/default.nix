{ lib, pkgs, config, ... }:

let
  cfg = config.superkey.sway;
in
{
  imports = [
    ./keys.nix
    ./theme.nix
  ];

  options.superkey.sway = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.superkey.enable;
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

      extraSessionCommands = ''
        export _JAVA_AWT_WM_NONREPARENTING=1
        export GTK2_RC_FILES=${pkgs.gnome.gnome-themes-extra}/share/themes/Adwaita-dark/gtk-2.0/gtkrc
        export GTK_THEME=Adwaita:dark
        export QT_QPA_PLATFORM=wayland
        export QT_STYLE_OVERRIDE=Adwaita-Dark
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        export SDL_VIDEODRIVER=wayland
      '';
    };
  };
}
