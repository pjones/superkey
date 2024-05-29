{ lib, pkgs, config, ... }:

let
  cfg = config.programs.pjones.swayfx;

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
    (direction: key: {
      # Focus a window in the given direction:
      "${modifier}+${key}" = "focus ${direction}";

      # Move a window in the given direction:
      "${modifier}+Shift+${key}" = "move ${direction}";
    })
    motion);

  # Switch workspace, move window to workspace:
  workspaces = lib.foldl' lib.mergeAttrs { } (builtins.map
    (workspace:
      let
        key = toString (if workspace.number == 10 then 0 else workspace.number);
        name = "${toString workspace.number}:${workspace.name}";
      in
      {
        # Switch to a workspace by its number:
        "${modifier}+${key}" = "workspace number ${name}";

        # Move the focused window/container to a workspace:
        "${modifier}+Shift+${key}" = "move container to workspace number ${name}";
      })
    (lib.zipListsWith (number: name: { inherit number name; })
      (lib.range 1 10)
      [ "GTD" "Social" "Hacking" "Media" "Meetings" "School" "RFA1" "RFA2" "Spare" "Web" ]));

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
    wayland.windowManager.sway.config = {
      inherit modifier;
      inherit (motion) left down up right;

      keybindings = windows // workspaces // {
        # Misc workspace bindings:
        "${modifier}+apostrophe" = "workspace back_and_forth";

        # Monitors:
        "${modifier}+greater" = "focus output right";
        "${modifier}+less" = "focus output left";

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
        "${modifier}+p" = "mode scratchpad";
        "${modifier}+r" = "mode resize";
        "${modifier}+s" = "mode swap";
        "${modifier}+w" = "mode layout";

        # Launching applications:
        "${modifier}+e" = "exec emacs";
      };

      floating = {
        inherit modifier;
      };

      modes.layout = mkMode {
        "0" = "kill; mode default";
        "1" = "fullscreen toggle; mode default";
        "2" = "split vertical; mode default";
        "3" = "split horizontal; mode default";
        "d" = "layout default; mode default";
        "h" = "layout splith; mode default";
        "s" = "layout stacking; mode default";
        "space" = "layout toggle all";
        "t" = "layout tabbed; mode default";
        "v" = "layout splitv; mode default";
        "f" = "floating toggle; mode default";
      };

      modes.focus = mkMode {
        "${motion.down}" = "focus child; mode default";
        "${motion.left}" = "focus prev; mode default";
        "${motion.right}" = "focus next; mode default";
        "${motion.up}" = "focus parent; mode default";
        "c" = "focus child; mode default";
        "f" = "focus floating; mode default";
        "p" = "focus parent; mode default";
        "t" = "focus tiling; mode default";
        "u" = "[urgent=latest] focus; mode default";
      };

      modes.mark = mkMarkMode (char: "mark --toggle ${char}");
      modes.swap = mkMarkMode (char: "swap container with mark ${char}");
      modes.jump = mkMarkMode (char: "[con_mark=\"${char}\"] focus");

      modes.resize = mkMode {
        "${motion.left}" = "resize shrink width 10 px";
        "${motion.down}" = "resize grow height 10 px";
        "${motion.up}" = "resize shrink height 10 px";
        "${motion.right}" = "resize grow width 10 px";
      };

      modes.scratchpad = mkMode {
        "p" = "scratchpad show";
        "m" = "move window to scratchpad; mode default";
        "r" = "floating disable; mode default";
      };
    };
  };
}
