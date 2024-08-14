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

  # Focus the next container visually:
  visualFocus = direction:
    let dirChar = builtins.substring 0 1 direction;
    in "sway-overfocus split-${dirChar}t float-${dirChar}t";

  # Window focus and movement:
  windows = lib.foldl' lib.mergeAttrs { } (lib.mapAttrsToList
    (direction: key: {
      # Focus a (split) window in the given direction:
      "${modifier}+${key}" = "exec ${visualFocus direction}";

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
  mkMarkModeMod = mod: command: mkMode (builtins.listToAttrs (map
    (char: {
      name = if mod != null then "${mod}+${char}" else char;
      value = "${command char}; mode default";
    })
    marks));

  mkMarkMode = mkMarkModeMod null;

  gromit-toggle =
    pkgs.writeShellScript "gromit-toggle"
      (builtins.readFile ../../support/scripts/gromit-mpx-toggle.sh);

  scratchpad-toggle =
    pkgs.writeShellScript "sway-scratchpad-toggle"
      (builtins.readFile ../../support/scripts/sway-scratchpad-toggle.sh);

  scratchpad-push =
    pkgs.writeShellScript "sway-scratchpad-push"
      (builtins.readFile ../../support/scripts/sway-scratchpad-push.sh);

  scratchpad-pop =
    pkgs.writeShellScript "sway-scratchpad-pop"
      (builtins.readFile ../../support/scripts/sway-scratchpad-pop.sh);

  scratchpad-fetch =
    pkgs.writeShellScript "sway-scratchpad-fetch"
      (builtins.readFile ../../support/scripts/sway-scratchpad-fetch.sh);
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      brightnessctl # This program allows you read and control device brightness
      pamixer # Pulseaudio command line mixer
      playerctl # Command-line utility for controlling media players
      sway-easyfocus # A tool to help efficiently focus windows in Sway
      sway-overfocus # "Better" focus navigation for sway
    ];

    wayland.windowManager.sway.config = {
      inherit modifier;
      inherit (motion) left down up right;

      keybindings = windows // {
        # Windows:
        "${modifier}+c" = "fullscreen toggle";
        "${modifier}+o" = "exec sway-easyfocus";
        "${modifier}+Return" = "exec ${scratchpad-toggle}";
        "${modifier}+Shift+o" = "exec sway-easyfocus swap --focus; mode default";
        "${modifier}+Tab" = "exec swaync-client -t; mode default";
        "${modifier}+u" = "[urgent=latest] focus; mode default";

        # Focus for groups:
        "${modifier}+n" = "exec sway-overfocus group-rw group-dw";
        "${modifier}+p" = "exec sway-overfocus group-lw group-uw";

        # Misc workspace bindings:
        "${modifier}+apostrophe" = "workspace back_and_forth";
        "${modifier}+Shift+period" = "workspace next_on_output";
        "${modifier}+Shift+comma" = "workspace prev_on_output";

        # Monitors:
        "${modifier}+period" = "focus output right";
        "${modifier}+comma" = "focus output left";

        # Swap two monitors:
        "${modifier}+d" = builtins.concatStringsSep "; " [
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
        "${modifier}+s" = "mode scratchpad";
        "${modifier}+w" = "mode window";

        # Launching applications:
        "${modifier}+e" = "exec e -c";
        "${modifier}+space" = "exec rofi-launcher.sh";
        Print = "exec screenshot";

        # Gromit-MPX:
        F4 = "exec ${gromit-toggle}";
        F5 = "exec gromit-mpx --toggle";
        F6 = "exec gromit-mpx --clear";

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
        "f" = "floating toggle; mode default";
        "h" = "layout splith; layout tabbed; mode default";
        "n" = "split vertical; mode default";
        "o" = "mode opacity";
        "s" = "mode swap";
        "Shift+s" = "layout stacking; mode default";
        "space" = "layout toggle all";
        "t" = "layout tabbed; mode default";
        "v" = "layout splitv; mode default";
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

      modes.opacity =
        let
          set = tenth: {
            name = toString tenth;
            value = "opacity set 0.${toString tenth}";
          };
        in
        mkMode
          {
            "${motion.down}" = "opacity minus 0.05";
            "${motion.up}" = "opacity plus 0.05";
            "o" = "opacity set 1.0; mode default";
          } // lib.listToAttrs (map set (lib.range 0 9));

      modes.mark = mkMarkMode (char: "mark --add --toggle ${char}");
      modes.jump = mkMarkMode (char: "[con_mark=\"${char}\"] focus");

      modes.resize = mkMode {
        "${motion.left}" = "resize shrink width 10 px";
        "${motion.down}" = "resize grow height 10 px";
        "${motion.up}" = "resize shrink height 10 px";
        "${motion.right}" = "resize grow width 10 px";
      };

      modes.swap =
        let
          swapInDirection = dir: pkgs.writeShellScript "sway-swap-${dir}" ''
            swaymsg -- mark --add _swap
            ${visualFocus dir}
            swaymsg -- swap container with mark _swap
            swaymsg -- '[con_mark="_swap"]' focus
            swaymsg -- unmark _swap
          '';

          motionBindings = lib.listToAttrs (
            lib.mapAttrsToList
              (direction: key: {
                name = "${key}";
                value = "exec ${swapInDirection direction}";
              })
              motion);
        in
        motionBindings // mkMode {
          "g" = "mode swap_with_mark";
        };

      modes.swap_with_mark = mkMarkMode (char: "swap container with mark ${char}");

      modes.scratchpad =
        (mkMarkMode (char: "exec ${scratchpad-fetch} ${char}")) //
        (mkMarkModeMod modifier (char: "exec ${scratchpad-push} ${char}")) // {
          "BackSpace" = "exec ${scratchpad-pop}; mode default";
          "Space" = "scratchpad show"; # Cycle through scratchpads.
        };
    };

    wayland.windowManager.sway.extraConfig = ''
      bindsym --release --no-repeat Cancel exec ${config.superkey.swaylock.forceLockCmd}
    '' + lib.concatStringsSep "\n" [ workspaces ];
  };
}
