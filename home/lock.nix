# Interface for locking the screen.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.superkey.lock;

  lockTimeout = cfg.lockAfterMin * 60;
  secureTimeout = cfg.secureAfterMin * 60;
  blankTimeout = lockTimeout + 60;

  # Path to tools we need:
  loginctl = "${pkgs.systemd}/bin/loginctl";
  pre-suspend-script = "${pkgs.pjones.superkey-scripts}/bin/superkey-pre-suspend.sh";

  # Script that locks the screen after finding a suitable background
  # image.
  lockCmd = pkgs.writeShellApplication {
    name = "lock";
    runtimeInputs = [
      pkgs.pjones.superkey-scripts
    ];
    text = ''
      # Ensure the lock screen tool *always* starts:
      trap "exec ${cfg.screenLockCmd}" ERR

      default_lock_image=${../support/images/lock.png}
      selected_image=

      if [ -d "${cfg.imagePath}" ]; then
        selected_image=$(superkey-random-file.sh -i -d "${cfg.imagePath}" -D "$default_lock_image")
      elif [ -e "${cfg.imagePath}" ]; then
        selected_image="${cfg.imagePath}"
      else
        selected_image=$default_lock_image
      fi

      if [ -n "$selected_image" ] && [ -e "$selected_image" ]; then
        mkdir --parents "$(dirname "${cfg.imageCachePath}")"
        ln --force --symbolic "$selected_image" "${cfg.imageCachePath}"
      fi

      exec ${cfg.screenLockCmd}
    '';
  };

  # Script that is run by swayidle when it's time to blank the screen.
  onIdleCommand = pkgs.writeShellApplication {
    name = "on-superkey-idle";
    runtimeInputs = [
      config.wayland.windowManager.niri.package
      pkgs.pjones.superkey-scripts
    ];
    text = ''
      ${cfg.stopAllInhibitorsCmd} || :
      superkey-output.sh -O
    '';
  };

  # Script that is run by swayidle when it's time to wake the screen.
  onNotIdleCommand = pkgs.writeShellApplication {
    name = "on-superkey-not-idle";
    runtimeInputs = [
      config.wayland.windowManager.niri.package
      pkgs.pjones.superkey-scripts
    ];
    text = ''
      superkey-output.sh -o
      ${cfg.startAllInhibitorsCmd} || :
    '';
  };

in
{
  options.superkey.lock = {
    lockAfterMin = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = ''
        Automatically lock the screen after the given number of
        minutes of being idle.
      '';
    };

    secureAfterMin = lib.mkOption {
      type = lib.types.int;
      default = 120;
      description = ''
        Automatically remove SSH/GPG keys after this many minutes of
        being idle.
      '';
    };

    imageCachePath = lib.mkOption {
      type = lib.types.path;
      default = "${config.xdg.cacheHome}/superkey/lock-image";
      internal = true;
      description = ''
        Internal path where the selected lock image will appear.
      '';
    };

    imagePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/documents/pictures/backgrounds/lock-screen";
      description = ''
        Path to the image or directory of images to use for the lock
        screen.
      '';
    };

    screenLockCmd = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = ''
        A shell command that starts a graphical lock screen.
      '';
    };

    forceLockCmd = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.systemd}/bin/loginctl lock-session";
      description = ''
        A shell command that will lock the current session.
      '';
    };

    stopAllInhibitorsCmd = lib.mkOption {
      type = lib.types.str;
      default = "echo 'No inhibitor stop script specified'";
      description = ''
        A shell command that will stop all idle inhibitors.
      '';
    };

    startAllInhibitorsCmd = lib.mkOption {
      type = lib.types.str;
      default = "echo 'No inhibitor start script specified'";
      description = ''
        A shell command that will start all idle inhibitors.
      '';
    };
  };

  config = lib.mkIf config.superkey.enable {
    home.packages = [ pkgs.wayland-pipewire-idle-inhibit ];

    xdg.desktopEntries = {
      lock-screen = {
        name = "Force Lock Session";
        exec = "${cfg.forceLockCmd}";
        icon = "emblem-system";
        terminal = false;
        categories = [ "System" ];
      };
    };

    services.swayidle = {
      enable = true;
      extraArgs = [ "-w" ];

      timeouts = [
        {
          timeout = lockTimeout;
          command = "${loginctl} lock-session";
        }
        {
          timeout = secureTimeout;
          command = pre-suspend-script;
        }
        {
          timeout = blankTimeout;
          command = "${onIdleCommand}/bin/on-superkey-idle";
          resumeCommand = "${onNotIdleCommand}/bin/on-superkey-not-idle";
        }
      ];
    };

    systemd.user.services.screen-lock = {
      # The targets used here are created by the NixOS setting:
      # services.systemd-lock-handler.
      Unit = {
        Description = "Screen locker for Wayland";
        PartOf = [ "lock.target" ];
        OnSuccess = [ "unlock.target" ];
        Before = [ "lock.target" ];
      };

      Service = {
        Type = "exec";
        ExecStart = "${lockCmd}/bin/lock";
        Restart = "on-failure";
        RestartSec = 0;
      };

      Install = {
        WantedBy = [ "lock.target" ];
      };
    };

    xdg.configFile."wayland-pipewire-idle-inhibit/config.toml".source =
      let
        tomlFormat = pkgs.formats.toml { };
        toToml = tomlFormat.generate "wayland-pipewire-idle-inhibit.toml";
      in
      toToml {
        verbosity = "INFO";
        media_minimum_duration = 5;
        idle_inhibitor = "wayland";

        sink_whitelist = [
          { name = "Scarlett"; }
          { name = "Office"; }
          { name = "Earbuds"; }
          { name = "Built-in"; }
        ];

        node_blacklist = [ ];
      };

    systemd.user.services.wayland-pipewire-idle-inhibit = {
      Unit = {
        Description = "Inhibit the screen locker when using audio";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.wayland-pipewire-idle-inhibit}/bin/wayland-pipewire-idle-inhibit";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
