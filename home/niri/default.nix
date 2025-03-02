{ config, lib, ... }:

let
  cfg = config.superkey.niri;
  colors = config.superkey.theme.colors;
in
{
  imports = [
    ./module.nix
  ];

  options.superkey.niri = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.superkey.compositor == "niri";
      description = "Enable Niri and related configuration.";
    };
  };

  config = lib.mkIf (config.superkey.enable && cfg.enable) {
    wayland.windowManager.niri = {
      enable = true;
      extraPackages = [ ];

      settings = {
        prefer-no-csd = { };
        screenshot-path = "${config.home.homeDirectory}/documents/pictures/screenshots/%Y/Screenshot_%Y%m%d_%H%M%S.png";

        # FIXME: make this a global option.
        workspace =
          let
            names = [
              "GTD"
              "Social"
              "Hacking"
              "Media"
              "Meetings"
              "School"
              "Work"
              "Other"
              "Spare"
              "Web"
            ];
          in
          map (name: { _args = [ name ]; }) names;

        cursor = {
          xcursor-theme = config.gtk.cursorTheme.name;
          xcursor-size = config.gtk.cursorTheme.size;
          hide-when-typing = { };
          hide-after-inactive-ms = 1000;
        };

        hotkey-overlay = {
          skip-at-startup = { };
        };

        input = {
          keyboard.xkb = {
            layout = "us";
            variant = "altgr-intl";
            options = "compose:menu,lv3:ralt_switch";
          };

          touchpad = {
            click-method = "button-areas";
            dwt = { };
            scroll-method = "two-finger";
          };

          mouse = { };
          trackpoint = { };

          warp-mouse-to-focus = { };
          focus-follows-mouse._props = { max-scroll-amount = "0%"; };
        };

        layout = {
          gaps = 16;
          center-focused-column = "on-overflow";

          #preset-column-widths.proportion = [ 0.33333 0.5 0.66667 ];
          #preset-window-heights.proportion = [ 0.33333 0.5 0.66667 ];
          default-column-width = { };

          focus-ring = {
            width = 4;
            active-color = colors.base0D;
            inactive-color = colors.base01;

            active-gradient._props = {
              "from" = "red";
              "to" = "orange";
              "angle" = 45;
              "in" = "oklch longer hue";
              "relative-to" = "workspace-view";
            };
          };

          border.off = { };

          # FIXME: insert-hint

          shadow.on = { };

          struts = {
            left = 64;
            right = 64;
            top = 20;
            bottom = 20;
          };

          # FIXME: a lot more to configure here:
          tab-indicator = {
            hide-when-single-tab = { };
            position = "bottom";
          };
        };

        window-rule = [
          {
            geometry-corner-radius = 8;
            clip-to-geometry = true;
          }

          # match is-window-cast-target=true
          # https://github.com/YaLTeR/niri/discussions/1162
        ];

        binds =
          let
            audio = cmd: {
              _props.allow-when-locked = true;
              spawn = cmd;
            };

            cooldown = cmd: {
              _props.cooldown-ms = 150;
              ${cmd} = { };
            };

            shell = cmd: {
              spawn = [ "sh" "-c" cmd ];
            };
          in
          {
            # Focus and move windows:
            "Mod+Ctrl+A".focus-column-first = { };
            "Mod+Ctrl+E".focus-column-last = { };
            "Mod+H".focus-column-left = { };
            "Mod+J".focus-window-down = { };
            "Mod+K".focus-window-up = { };
            "Mod+L".focus-column-right = { };
            "Mod+Shift+A".move-column-to-first = { };
            "Mod+Shift+E".move-column-to-last = { };
            "Mod+Shift+H".move-column-left = { };
            "Mod+Shift+J".move-window-down = { };
            "Mod+Shift+K".move-window-up = { };
            "Mod+Shift+L".move-column-right = { };
            "Mod+WheelScrollLeft".focus-column-left = { };
            "Mod+WheelScrollRight".focus-column-right = { };

            # Other window and column controls:
            "Mod+C".center-window = { };
            "Mod+Comma".consume-window-into-column = { };
            "Mod+Ctrl+H".set-column-width = "-10%";
            "Mod+Ctrl+J".set-window-height = "-10%";
            "Mod+Ctrl+K".set-window-height = "+10%";
            "Mod+Ctrl+L".set-column-width = "+10%";
            "Mod+Equal".reset-window-height = { };
            "Mod+F".toggle-window-floating = { };
            "Mod+M".maximize-column = { };
            "Mod+Period".expel-window-from-column = { };
            "Mod+R".switch-preset-column-width = { };
            "Mod+Shift+M".fullscreen-window = { };
            "Mod+Shift+Q".close-window = { };
            "Mod+Shift+R".switch-preset-window-height = { };
            "Mod+Shift+T".switch-focus-between-floating-and-tiling = { };
            "Mod+T".toggle-column-tabbed-display = { };

            # Workspaces:
            "Mod+1".focus-workspace = [ 1 ];
            "Mod+2".focus-workspace = [ 2 ];
            "Mod+3".focus-workspace = [ 3 ];
            "Mod+4".focus-workspace = [ 4 ];
            "Mod+5".focus-workspace = [ 5 ];
            "Mod+6".focus-workspace = [ 6 ];
            "Mod+7".focus-workspace = [ 7 ];
            "Mod+8".focus-workspace = [ 8 ];
            "Mod+9".focus-workspace = [ 9 ];
            "Mod+0".focus-workspace = [ 10 ];

            "Mod+Shift+1".move-window-to-workspace = [ 1 ];
            "Mod+Shift+2".move-window-to-workspace = [ 2 ];
            "Mod+Shift+3".move-window-to-workspace = [ 3 ];
            "Mod+Shift+4".move-window-to-workspace = [ 4 ];
            "Mod+Shift+5".move-window-to-workspace = [ 5 ];
            "Mod+Shift+6".move-window-to-workspace = [ 6 ];
            "Mod+Shift+7".move-window-to-workspace = [ 7 ];
            "Mod+Shift+8".move-window-to-workspace = [ 8 ];
            "Mod+Shift+9".move-window-to-workspace = [ 9 ];
            "Mod+Shift+0".move-window-to-workspace = [ 10 ];

            "Mod+Apostrophe".focus-workspace-previous = { };
            "Mod+Shift+comma".focus-workspace-up = { };
            "Mod+Shift+period".focus-workspace-down = { };
            "Mod+WheelScrollDown" = cooldown "focus-workspace-down";
            "Mod+WheelScrollUp" = cooldown "focus-workspace-up";

            # Monitors:
            "Mod+U".focus-monitor-next = { };
            "Mod+Y".focus-monitor-previous = { };
            "Mod+D".spawn = [ "superkey-swap-monitor.sh" ];

            # Applications and utilities:
            "Mod+E".spawn = [ "e" "-c" ];
            "Mod+Escape".toggle-keyboard-shortcuts-inhibit = { };
            "Mod+I".spawn = [ "toggle-presenter-mode" ];
            "Mod+Print".screenshot-window = { };
            "Mod+Return".spawn = [ "eterm" ];
            "Mod+Shift+Slash".show-hotkey-overlay = { };
            "Mod+Space".spawn = [ "rofi-launcher.sh" ];
            "Mod+Tab".spawn = [ "swaync-client -t" ];
            Cancel = shell config.superkey.swaylock.forceLockCmd;
            Print.screenshot = { };
            XF86AudioMedia = shell config.superkey.commands.sendClipboard;
            XF86Launch5 = shell config.superkey.commands.sendClipboard;
            XF86MonBrightnessDown.spawn = [ "brightnessctl" "set" "-5%" ];
            XF86MonBrightnessUp.spawn = [ "brightnessctl" "set" "+5%" ];

            # Audio commands:
            XF86AudioLowerVolume = audio [ "pamixer" "--decrease" "5" ];
            XF86AudioMute = audio [ "pamixer" "--toggle-mute" ];
            XF86AudioNext = audio [ "playerctl" "next" ];
            XF86AudioPlay = audio [ "playerctl" "play-pause" ];
            XF86AudioPrev = audio [ "playerctl" "previous" ];
            XF86AudioRaiseVolume = audio [ "pamixer" "--increase" "5" ];
            XF86Launch6 = audio [ "superkey-paswitch.sh" ];
          };
      };

      extraSessionCommands = config.superkey.commands.extraSessionCommands;
    };
  };
}
