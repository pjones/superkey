{ ... }:

{
  config = {
    environment.sessionVariables = {
      # WLR_NO_HARDWARE_CURSORS = "1";
      # WLR_RENDERER_ALLOW_SOFTWARE = "1";
      WLR_RENDERER = "pixman";

      # Fixed location for tests:
      SWAYSOCK = "/tmp/sway-ipc.sock";
    };

    hardware.opengl.enable = true;
    virtualisation.qemu.options = [
      "-vga none"
      "-device virtio-gpu-pci"
    ];

    home-manager.users.pjones = { ... }: {
      superkey.primaryOutput = "Virtual-1";
    };
  };
}
