{ config, lib, pkgs, ... }:

let
  cfg = config.superkey;
in
{
  options.superkey.clipboard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = ''
        Enable a persistent clipboard, even after closing
        applications.
      '';
    };
  };

  config = lib.mkIf cfg.clipboard.enable {
    systemd.user.services.wl-clip-persist = {
      Unit = {
        Description = "Clipboard management daemon";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
