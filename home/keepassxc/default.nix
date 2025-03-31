{ config, lib, pkgs, ... }:

let
  cfg = config.superkey.programs.keepassxc;
in
{
  options.superkey.programs.keepassxc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.superkey.enable;
      description = "Configure and run KeePassXC";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      keepassxc # Offline password manager with many features
    ];

    # TODO: Merge configuration items.
    # [GUI]
    # MinimizeOnClose=true
    # MinimizeToTray=true
    # ShowTrayIcon=true
    # TrayIconAppearance=colorful

    systemd.user.services.keepassxc = {
      Unit = {
        Description = "Offline password manager with many features";
        Documentation = "https://keepassxc.org/docs/";
        PartOf = [ "graphical-session.target" ];
        Requires = [ "tray.target" ];
        After = [ "graphical-session.target" "tray.target" ];
      };

      Service = {
        ExecStart = "${pkgs.keepassxc}/bin/keepassxc --minimized";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
