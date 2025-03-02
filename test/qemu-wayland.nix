{ config, lib, ... }:

{
  config = lib.mkMerge [
    {
      hardware.graphics.enable = true;
    }

    (lib.mkIf (config.superkey.compositor == "sway") {
      environment.sessionVariables = {
        WLR_RENDERER = "pixman";
      };

      virtualisation.qemu.options = [
        "-vga none"
        "-device virtio-gpu-pci"
      ];
    })
  ];
}
