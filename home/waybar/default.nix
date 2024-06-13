{ lib, pkgs, config, ... }:

let
  cfg = config.superkey.waybar;
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
        mode = "dock";
        layer = "top";
        exclusive = true;
        position = "bottom";
        height = 24;

        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-right = [ "clock" ];

        "sway/workspaces" = {
          all-outputs = true;
          current-only = true;
        };

        clock = {
          format = " {:%A, %d %B %Y @ %H:%M (%Z)}";
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
              today = "<span>{}</span>";
            };
          };

          actions = {
            on-click = "tz_down";
            on-click-right = "tz_up";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
      };
    };

    xdg.configFile."waybar/style.css" = {
      source = "${config.superkey.theme}/waybar/waybar.css";
      onChange = ''
        ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
      '';
    };
  };
}
