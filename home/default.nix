{ config, lib, pkgs, ... }:
{
  imports = [
    ./sway
    ./swayfx
    ./waybar
  ];

  options.waynix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Wayland configuration.";
    };

    theme = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = "A theme package.";
    };
  };

  config = lib.mkIf config.waynix.enable {
    home.packages = with pkgs; [
      jq
      pjones.desktop-scripts
      pjones.rofirc-wayland
      wayland-utils
      wev
      wl-clipboard
    ];
  };
}
