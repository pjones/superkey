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
    superkey.compositorPackage = config.wayland.windowManager.niri.package;

    wayland.windowManager.niri = {
      enable = true;
      extraPackages = [ ];

      settings = {
        prefer-no-csd = { };
        screenshot-path = "${config.home.homeDirectory}/documents/pictures/screenshots/%Y/Screenshot_%Y%m%d_%H%M%S.png";

        workspace =
          map (name: { _args = [ name ]; })
            config.superkey.workspaceNames;

        cursor = {
          xcursor-theme = config.gtk.cursorTheme.name;
          xcursor-size = config.gtk.cursorTheme.size;
          hide-when-typing = { };
          hide-after-inactive-ms = 30000;
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
            drag-lock = { };
            dwt = { };
          };

          mouse = { };
          trackpoint = { };

          warp-mouse-to-focus = { };
          focus-follows-mouse._props = { max-scroll-amount = "0%"; };
        };

        layout = {
          gaps = 16;
          center-focused-column = "never";

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

          border = {
            off = { };
            width = 4;
          };

          # FIXME: insert-hint

          shadow = {
            on = { };
            softness = 30;
            spread = 5;
            offset._props = { x = 0; y = 5; };
            color = "#0007";
          };

          struts = {
            left = 5;
            right = 5;
            top = 0;
            bottom = 0;
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

          # Windows that are being cast:
          #
          # https://github.com/YaLTeR/niri/discussions/1162
          {
            match._props.is-window-cast-target = true;

            focus-ring = {
              width = 2;
              active-color = "#f38ba8";
              inactive-color = "#7d0d2d";
            };

            border = {
              on = { };
              width = 2;
              active-color = "#f38ba8";
              inactive-color = "#7d0d2d";
            };

            shadow = {
              color = "#7d0d2d70";
            };

            tab-indicator = {
              active-color = "#f38ba8";
              inactive-color = "#7d0d2d";
            };
          }

          # Inactive windows:
          # Not sure I like this:
          {
            match._props.is-focused = false;
            opacity = 0.9;
          }

          # Apps that should float (using their title):
          {
            match._props.title = "OpenSSH Authentication Passphrase request";
            open-floating = true;
          }

          # Apps that should float (using their app-id):
          {
            match._props.app-id = "udiskie|wdisplays";
            open-floating = true;
          }

          # Apps that always start at 1/3 of the display size:
          {
            match._props.app-id = "emacs";
            default-column-width.proportion = 0.33;
          }

          # Apps that can take up half of the screen:
          {
            match._props.app-id = "chromium|firefox|librewolf";
            default-column-width.proportion = 0.5;
          }

          # KeePassXC
          {
            match._props = {
              app-id = "org.keepassxc.KeePassXC";
              title = "Access Request";
            };
            open-floating = true;
          }
          {
            match._props.app-id = "org.keepassxc.KeePassXC";
            block-out-from = "screen-capture";
          }
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

            workspaces =
              lib.mergeAttrsList (lib.imap1
                (index: name:
                  let
                    key = builtins.toString (lib.mod index 10);
                  in
                  {
                    "Mod+${key}".focus-workspace = [ name ];
                    "Mod+Shift+${key}".move-window-to-workspace = [ name ];
                  })
                config.superkey.workspaceNames);
          in
          workspaces //
          {
            # Focus and move windows:
            "Mod+Ctrl+A".focus-column-first = { };
            "Mod+Ctrl+E".focus-column-last = { };
            "Mod+H".focus-column-left-or-last = { };
            "Mod+J".focus-window-down-or-top = { };
            "Mod+K".focus-window-up-or-bottom = { };
            "Mod+L".focus-column-right-or-first = { };
            "Mod+Semicolon".focus-window-previous = { };
            "Mod+Shift+A".move-column-to-first = { };
            "Mod+Shift+E".move-column-to-last = { };
            "Mod+Shift+H".move-column-left = { };
            "Mod+Shift+J".move-window-down = { };
            "Mod+Shift+K".move-window-up = { };
            "Mod+Shift+L".move-column-right = { };
            "Mod+WheelScrollLeft".focus-column-left = { };
            "Mod+WheelScrollRight".focus-column-right = { };

            # Other window and column controls:
            "Mod+Shift+Bracketleft".swap-window-left = { };
            "Mod+Shift+Bracketright".swap-window-right = { };
            "Mod+C".center-window = { };
            "Mod+Ctrl+H".set-column-width = "-5%";
            "Mod+Ctrl+J".set-window-height = "-5%";
            "Mod+Ctrl+K".set-window-height = "+5%";
            "Mod+Ctrl+L".set-column-width = "+5%";
            "Mod+Equal".reset-window-height = { };
            "Mod+F".toggle-window-floating = { };
            "Mod+M".maximize-column = { };
            "Mod+R".switch-preset-column-width = { };
            "Mod+Shift+Comma".consume-or-expel-window-left = { };
            "Mod+Shift+M".fullscreen-window = { };
            "Mod+Shift+Period".consume-or-expel-window-right = { };
            "Mod+Shift+Q".close-window = { };
            "Mod+Shift+R".switch-preset-window-height = { };
            "Mod+Shift+T".switch-focus-between-floating-and-tiling = { };
            "Mod+T".toggle-column-tabbed-display = { };

            # Workspaces:
            "Mod+Apostrophe".focus-workspace-previous = { };
            "Mod+Down".focus-workspace-down = { };
            "Mod+Left".move-workspace-to-monitor-previous = { };
            "Mod+Right".move-workspace-to-monitor-next = { };
            "Mod+Up".focus-workspace-up = { };
            "Mod+WheelScrollDown" = cooldown "focus-workspace-down";
            "Mod+WheelScrollUp" = cooldown "focus-workspace-up";

            # Monitors:
            "Mod+Comma".focus-monitor-previous = { };
            "Mod+D".spawn = [ "superkey-swap-monitor.sh" ];
            "Mod+Period".focus-monitor-next = { };

            # Applications and utilities:
            "Mod+E".spawn = [ "e" "-c" ];
            "Mod+Escape".toggle-keyboard-shortcuts-inhibit = { };
            "Mod+I".spawn = [ "toggle-presenter-mode" ];
            "Mod+Print".screenshot-window = { };
            "Mod+Return".spawn = [ "eterm" ];
            "Mod+Shift+Slash".show-hotkey-overlay = { };
            "Mod+Space".spawn = [ "rofi-launcher.sh" ];
            "Mod+Tab".spawn = [ "swaync-client" "-t" ];
            Cancel = shell config.superkey.swaylock.forceLockCmd;
            Print.screenshot = { };
            XF86AudioMedia = shell config.superkey.commands.sendClipboard;
            XF86Launch5 = shell config.superkey.commands.sendClipboard;
            XF86MonBrightnessDown.spawn = [ "brightnessctl" "set" "5%-" ];
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
