{ self }:

{ ... }:

{
  imports = [
    self.inputs.home-manager.nixosModules.home-manager
    self.nixosModules.default
  ];

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

    users.users.pjones = {
      isNormalUser = true;
      password = "password";
      extraGroups = [ "wheel" ];
    };

    # Enable NixOS settings:
    superkey.enable = true;

    # Enable Home Manager settings:
    home-manager = {
      backupFileExtension = "backup";
      useGlobalPkgs = true;
      useUserPackages = true;

      users.pjones = { config, ... }: {
        imports = [
          self.homeManagerModules.vm
          self.inputs.emacsrc.homeManagerModules.wayland
        ];

        home.username = "pjones";
        home.homeDirectory = "/home/pjones";
        programs.pjones.emacsrc.enable = true;

        superkey = {
          enable = true;
          primaryOutput = "Virtual-1";
        };
      };
    };
  };
}
