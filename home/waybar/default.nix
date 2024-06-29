{ lib, pkgs, config, ... }:

let
  cfg = config.superkey.waybar;
  colors = config.superkey.theme.colors;
in
{
  options.superkey.waybar = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.superkey.enable;
      description = "Enable Waybar and related configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      style = null;

      settings.main = {
        output = config.superkey.primaryOutput;
        name = lib.mkDefault "main";
        mode = "dock";
        layer = "top";
        exclusive = true;
        position = "bottom";
        height = lib.mkDefault 24;

        modules-left = [
          "sway/mode"
          "sway/workspaces"
          "sway/window"
        ];

        modules-center = [
          "keyboard-state"
          "mpris"
        ];

        modules-right = [
          "wireplumber"
          "backlight"
          "battery"
          "clock"
          "idle_inhibitor"
          "tray"
        ];

        "sway/mode" = {
          format = "<span>󰀦 </span> Mode: {} <span> 󰀦</span>";
        };

        "sway/workspaces" = {
          format = "<span color='${colors.base0B}'>󰍹 </span> {name}";
          all-outputs = true;
          current-only = true;
        };

        "sway/window" = {
          format = "<span color='${colors.base0B}'> </span> {title}";
          max-length = 50;
          icon = false;
          rewrite = {
            "(.*) - Mozilla Firefox" = "$1";
            "Emacs:\s+(.*)" = "$1";
          };
        };

        keyboard-state = {
          capslock = true;
          format = "{icon}";
          format-icons = {
            locked = "<span color='${colors.base08}'>󰪛 </span> Caps Lock";
            unlocked = "";
          };
        };

        mpris = {
          format = "<span color='${colors.base0B}'>{status_icon} </span> {dynamic}";
          format-paused = "<span color='${colors.base0A}'>{status_icon} </span> {dynamic}";
          format-stopped = "";
          dynamic-order = [ "artist" "title" "album" ];
          dynamic-len = 45;
          status-icons = {
            playing = "";
            paused = "";
            stopped = "";
          };
        };

        backlight = {
          format = "<span color='${colors.base0B}'>{icon} </span> {percent}%";
          format-icons = [ "󰃞" "󰃟" "󰃠" ];
        };

        battery =
          let
            mkFormat = color:
              "<span color='${color}'>{icon} </span> {capacity}% ({time}@{power})";
          in
          {
            format = "<span color='${colors.base0B}'> </span> {timeTo}";
            format-discharging = mkFormat colors.base0B;
            format-warning = mkFormat colors.base0E;
            format-critical = mkFormat colors.base05;
            format-time = "{H}:{m}";
            format-icons = [ "" "" "" "" "" ];
            states = {
              warning = 30;
              critical = 15;
            };
          };

        clock = {
          format = "<span color='${colors.base0B}' segment='sentence'> </span> {:%A, %d %B %Y <span color='${colors.base0B}' segment='sentence'> </span> %H:%M (%Z)}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";

          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='${colors.base09}'>{}</span>";
              days = "<span>{}</span>";
              weeks = "<span>{}</span>";
              weekdays = "<span>{}</span>";
              today = "<span color='${colors.base0B}'><b>{}</b></span>";
            };
          };

          actions = {
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "<span color='${colors.base0A}'>󰐩 </span>";
            deactivated = "<span color='${colors.base0B}'>󰐨 </span>";
          };
        };

        wireplumber = {
          format = "<span color='${colors.base0B}'>{icon} </span> {volume}%";
          format-muted = "<span color='${colors.base08}'></span>";
          on-click = "";
          format-icons = [ "" "" "" ];
        };

        tray = {
          spacing = 5;
          icon-size = 16;
          show-passive-items = true;
        };
      };
    };

    xdg.configFile."waybar/style.css" = {
      source = "${config.superkey.theme}/theme/waybar.css";
      onChange = ''
        ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
      '';
    };

    xdg.configFile."waybar/colors.css" = {
      source = "${config.superkey.theme}/theme/colors.css";
      onChange = ''
        ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
      '';
    };
  };
}
