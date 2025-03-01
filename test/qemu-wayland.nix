{ config, lib, ... }:

{
  config = {
    environment.sessionVariables = {
      # WLR_NO_HARDWARE_CURSORS = "1";
      # WLR_RENDERER_ALLOW_SOFTWARE = "1";
      WLR_RENDERER = "pixman";
    } // lib.optionalAttrs (config.superkey.compositor == "sway") {
      # Fixed location for tests:
      SWAYSOCK = "/tmp/compositor-ipc.sock";

      # May not be set in tests:
      XDG_CURRENT_DESKTOP = "sway";
    };

    hardware.graphics.enable = true;
    virtualisation.qemu.options = [
      "-vga none"
      "-device virtio-gpu-pci"
    ];

    home-manager.users.pjones = { ... }: {
      superkey.primaryOutput = "Virtual-1";
    };
  };
}
