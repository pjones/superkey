{ lib, pkgs, config, ... }:

let
  cfg = config.superkey.sway;

  # Some default keys:
  modifier = "Mod4";

  motion = {
    left = "h";
    down = "j";
    up = "k";
    right = "l";
  };

  # Window focus and movement:
  windows = lib.foldl' lib.mergeAttrs { } (lib.mapAttrsToList
    (direction: key:
      let dirChar = builtins.substring 0 1 direction;
      in
      {
        # Focus a (split) window in the given direction:
        "${modifier}+${key}" =
          "exec sway-overfocus split-${dirChar}t float-${dirChar}t";

        # Move a window in the given direction:
        "${modifier}+Shift+${key}" = "move ${direction}";
      })
    motion);

  # Switch workspace, move window to workspace.  Returns a string so
  # that workspaces are in the correct order.
  workspaces = lib.concatMapStringsSep "\n"
    (workspace:
      let
        key = toString (if workspace.number == 10 then 0 else workspace.number);
        name = "${toString workspace.number}:${workspace.name}";
      in
      ''
        bindsym ${modifier}+${key} workspace number ${name}
        bindsym ${modifier}+Shift+${key} move container to workspace number ${name}
      '')
    (lib.zipListsWith (number: name: { inherit number name; })
      (lib.range 1 10)
      [ "GTD" "Social" "Hacking" "Media" "Meetings" "School" "RFA1" "RFA2" "Spare" "Web" ]);

  # Ensure modes have an escape hatch:
  mkMode = bindings: bindings // {
    "Escape" = "mode default";
    "Control+g" = "mode default";
  };

  # Keys available for marking windows:
  marks = import ./alphabet.nix;

  # Make a mode out of all marks that run the given command:
  mkMarkMode = command: mkMode (builtins.listToAttrs (map
    (char: {
      name = char;
      value = "${command char}; mode default";
    })
    marks));

in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      brightnessctl # This program allows you read and control device brightness
      pamixer # Pulseaudio command line mixer
      playerctl # Command-line utility for controlling media players
    ];

    wayland.windowManager.sway.config = {
      inherit modifier;
      inherit (motion) left down up right;

      keybindings = windows // {
        # Commonly used features:
        "${modifier}+c" = "fullscreen toggle";

        # Focus for groups:
        "${modifier}+n" = "exec sway-overfocus group-rw group-dw";
        "${modifier}+p" = "exec sway-overfocus group-lw group-uw";

        # Misc workspace bindings:
        "${modifier}+apostrophe" = "workspace back_and_forth";
        "${modifier}+Shift+period" = "workspace next";
        "${modifier}+Shift+comma" = "workspace prev";

        # Monitors:
        "${modifier}+period" = "focus output right";
        "${modifier}+comma" = "focus output left";

        # Swap two monitors:
        "${modifier}+d" = builtins.concatStringsSep ";" [
          "focus output right"
          "move workspace to output left"
          "workspace back_and_forth"
          "move workspace to output right"
          "focus output right"
        ];

        # Activate modes:
        "${modifier}+f" = "mode focus";
        "${modifier}+g" = "mode jump";
        "${modifier}+m" = "mode mark";
        "${modifier}+r" = "mode resize";
        "${modifier}+s" = "mode swap";
        "${modifier}+w" = "mode window";
        "${modifier}+slash" = "mode scratchpad";

        # Launching applications:
        "${modifier}+e" = "exec e -c";
        "${modifier}+space" = "exec rofi-launcher.sh";
        Cancel = "exec loginctl lock-session";
        Print = "exec screenshot";

        # Audio:
        XF86AudioLowerVolume = "exec pamixer --decrease 5";
        XF86AudioRaiseVolume = "exec pamixer --increase 5";
        XF86AudioMute = "exec pamixer --toggle-mute";
        XF86AudioPlay = "exec playerctl play-pause";
        XF86AudioPrev = "exec playerctl previous";
        XF86AudioNext = "exec playerctl next";
        XF86Launch6 = "exec desktop-paswitch";

        # Screen Brightness:
        XF86MonBrightnessUp = "exec brightnessctl set +5%";
        XF86MonBrightnessDown = "exec brightnessctl set 5%-";
      };

      floating = {
        inherit modifier;
      };

      modes.window = mkMode {
        "0" = "kill; mode default";
        "1" = "fullscreen toggle; mode default";
        "2" = "split vertical; mode default";
        "3" = "split horizontal; mode default";
        "b" = "border toggle; mode default";
        "d" = "layout default; mode default";
        "h" = "layout splith; mode default";
        "s" = "layout stacking; mode default";
        "space" = "layout toggle all";
        "t" = "layout tabbed; mode default";
        "v" = "layout splitv; mode default";
        "f" = "floating toggle; mode default";
      };

      modes.focus = mkMode {
        "${motion.down}" = "focus down; mode default";
        "${motion.left}" = "focus left; mode default";
        "${motion.right}" = "focus right; mode default";
        "${motion.up}" = "focus up; mode default";
        "c" = "focus child; mode default";
        "f" = "focus floating; mode default";
        "n" = "focus next; mode default";
        "p" = "focus parent; mode default";
        "t" = "focus tiling; mode default";
        "u" = "[urgent=latest] focus; mode default";
      };

      modes.mark = mkMarkMode (char: "mark --toggle ${char}");
      modes.swap = mkMarkMode (char: "swap container with mark ${char}");
      modes.jump = mkMarkMode (char: "[con_mark=\"${char}\"] focus");

      modes.mark_scratchpad = mkMarkMode (char:
        "mark --add S${char}; move window to scratchpad"
      );

      modes.restore_scratchpad = mkMarkMode (char:
        "mark --toggle S${char}; floating disable"
      );

      modes.resize = mkMode {
        "${motion.left}" = "resize shrink width 10 px";
        "${motion.down}" = "resize grow height 10 px";
        "${motion.up}" = "resize shrink height 10 px";
        "${motion.right}" = "resize grow width 10 px";
      };

      modes.scratchpad =
        (mkMarkMode (char: "[con_mark=\"S${char}\"] scratchpad show")) // {
          "semicolon" = "exec swaync-client -t; mode default";
          "Shift+comma" = "mode restore_scratchpad";
          "Shift+period" = "mode mark_scratchpad";
          "slash" = "scratchpad show";
        };
    };

    wayland.windowManager.sway.extraConfig =
      lib.concatStringsSep "\n" [ workspaces ];
  };
}
