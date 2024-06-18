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
    home.packages = [
      pkgs.sway-audio-idle-inhibit
    ];

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      style = null;

      settings.main = {
        output = config.superkey.primaryOutput;
        mode = "dock";
        layer = "top";
        exclusive = true;
        position = "bottom";
        height = 24;

        modules-left = [
          "sway/workspaces"
          "sway/mode"
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
          "custom/audio_idle_inhibitor"
          "tray"
        ];

        "sway/workspaces" = {
          format = "<span color='${colors.green}'>󰍹 </span> {name}";
          all-outputs = true;
          current-only = true;
        };

        "sway/mode" = {
          format = "Mode: {}";
        };

        keyboard-state = {
          capslock = true;
          format = "{icon}";
          format-icons = {
            locked = "<span color='${colors.red}'>󰪛 </span> Caps Lock";
            unlocked = "";
          };
        };

        mpris = {
          format = "<span color='${colors.green}'>{status_icon} </span> {dynamic}";
          format-paused = "<span color='${colors.yellow}'>{status_icon} </span> {dynamic}";
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
          format = "<span color='${colors.green}'>{icon} </span> {percent}%";
          format-icons = [ "󰃞" "󰃟" "󰃠" ];
        };

        battery =
          let
            mkFormat = color:
              "<span color='${color}'>{icon} </span> {capacity}% ({time}@{power})";
          in
          {
            format = "<span color='${colors.green}'> </span> {timeTo}";
            format-discharging = mkFormat colors.green;
            format-warning = mkFormat colors.orange;
            format-critical = mkFormat colors.foreground;
            format-time = "{H}:{m}";
            format-icons = [ "" "" "" "" "" ];
            states = {
              warning = 30;
              critical = 15;
            };
          };

        clock = {
          format = "<span color='${colors.green}' segment='sentence'> </span> {:%A, %d %B %Y <span color='${colors.green}' segment='sentence'> </span> %H:%M (%Z)}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";

          timezones = [
            "Etc/UTC"
            "America/New_York"
            "America/Denver"
            "America/Los_Angeles"
          ];

          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span>{}</span>";
              days = "<span>{}</span>";
              weeks = "<span>{}</span>";
              weekdays = "<span>{}</span>";
              today = "<span color='${colors.green}'>{}</span>";
            };
          };

          actions = {
            on-click = "tz_down";
            on-click-right = "tz_up";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "<span color='${colors.red}'>󰐩 </span>";
            deactivated = "<span color='${colors.green}'>󰐨 </span>";
          };
        };

        "custom/audio_idle_inhibitor" = {
          format = "<span color='${colors.orange}'>{icon}</span>";
          exec = "sway-audio-idle-inhibit --dry-print-both-waybar";
          return-type = "json";
          format-icons = {
            none = "";
            output = "󰜟";
            input = "";
            output-input = "";
          };
        };

        wireplumber = {
          format = "<span color='${colors.green}'>{icon} </span> {volume}%";
          format-muted = "<span color='${colors.red}'></span>";
          on-click = "";
          format-icons = [ "" "" "" ];
        };
      };
    };

    xdg.configFile."waybar/style.css" = {
      source = "${config.superkey.theme}/waybar/waybar.css";
      onChange = ''
        ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
      '';
    };

    systemd.user.services.sway-audio-idle-inhibit = {
      Unit = {
        Description = "Inhibit the screen locker when using audio";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
