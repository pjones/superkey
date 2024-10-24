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
    wayland.windowManager.sway = {
      enable = true;
      checkConfig = false; # Currently broken

      systemd = {
        enable = true;
        variables = [ "--all" ];
      };

      config = {
        workspaceLayout = "default";

        focus.followMouse = "yes";
        focus.newWindow = "smart";
        focus.wrapping = "yes";
        focus.mouseWarping = "container";

        # Windows that should always be floating:
        floating.criteria = [
          { app_id = "udiskie"; }
          { app_id = "nwg-displays"; }
          { title = "OpenSSH Authentication Passphrase request"; }
        ];

        fonts = {
          names = [ "Atkinson Hyperlegible" ];
          style = "Regular";
          size = 12.0;
        };

        input."*" = {
          # https://math.dartmouth.edu/~sarunas/Linux_Compose_Key_Sequences.html
          xkb_layout = "us";
          xkb_variant = "altgr-intl";
          xkb_options = "compose:menu,level3:ralt_switch";
        };

        input."type:touchpad" = {
          click_method = "button_areas";
          tap = "disabled";
          drag = "disabled";
          dwt = "enabled"; # Disabled while typing.
          middle_emulation = "enabled";
          natural_scroll = "disabled";
        };

        input."type:tablet_tool" = {
          map_to_output = config.superkey.primaryOutput;
        };

        seat."*" = {
          hide_cursor = "when-typing enable";

          xcursor_theme = lib.concatStringsSep " " [
            config.gtk.cursorTheme.name
            (toString config.gtk.cursorTheme.size)
          ];
        };

        output."*" = {
          adaptive_sync = "on";
        };

        # This is so sway can talk to waybar:
        bars = lib.singleton {
          id = "bar-0";
          mode = "dock";
          position = "bottom";
          command = "true";
        };
      };

      extraConfig = ''
        default_border pixel 3
        default_floating_border pixel 3
        default_orientation auto
        titlebar_padding 10 5
        force_display_urgency_hint 1000
        popup_during_fullscreen leave_fullscreen
      '';

      extraSessionCommands = ''
        . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
        export _JAVA_AWT_WM_NONREPARENTING=1
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        export SDL_VIDEODRIVER=wayland
      '';
    };
  };
}
