{ lib, ... }:
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
}
