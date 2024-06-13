{ config, lib, pkgs, ... }:

let
  cfg = config.superkey;

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = [ ];
    text = ''
      grim -g "$(slurp)" - | satty --filename -
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      screenshot
      pkgs.grim
      pkgs.slurp
      pkgs.satty
    ];

    xdg.configFile."satty/config.toml".text = ''
      [general]
      copy-command = "wl-copy"
      output-filename = "${config.home.homeDirectory}/documents/pictures/screenshots/%Y/Screenshot_%Y%m%d_%H%M%S.png"
      early-exit = true
      initial-tool = "arrow"
    '';
  };
}
