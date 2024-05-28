{ self }:

{ lib, pkgs, modulesPath, ... }:
{
  imports = [
    self.inputs.home-manager.nixosModules.home-manager
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  config = {
    virtualisation = {
      diskSize = lib.mkDefault 8000; # MB
      memorySize = lib.mkDefault 2048; # MB

      sharedDirectories.home = {
        source = "$HOME";
        target = "/mnt";
      };

      forwardPorts = [{
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }];

      qemu.options = [
        "-vga none"
        "-device virtio-gpu-pci"
      ];
    };

    nixpkgs.flake.setNixPath = false;
    nix.nixPath = lib.mkForce [ "nixpkgs=${pkgs.path}" ];

    environment.sessionVariables = {
      # WLR_NO_HARDWARE_CURSORS = "1";
      # WLR_RENDERER_ALLOW_SOFTWARE = "1";
      WLR_RENDERER = "pixman";
    };

    hardware.opengl.enable = true;
    security.sudo.wheelNeedsPassword = false;
    services.openssh.enable = true;
    services.qemuGuest.enable = true;

    users.users.pjones = {
      isNormalUser = true;
      password = "password";
      extraGroups = [ "wheel" ];
    };

    home-manager.users.pjones = { ... }: {
      imports = [
        self.homeManagerModules.vm
        self.inputs.emacsrc.homeManagerModules.default
      ];

      home.username = "pjones";
      home.homeDirectory = "/home/pjones";
      programs.pjones.swayfx.enable = true;
      programs.pjones.emacsrc.enable = true;
      wayland.windowManager.sway.checkConfig = false;
    };
  };
}
