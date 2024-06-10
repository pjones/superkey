{ self }:

{ lib, pkgs, modulesPath, ... }:
let
  waybarWrapper = home: pkgs.writeShellScript "waybar-wrapper" ''
    ${home.programs.waybar.package}/bin/waybar -l debug
  '';
in
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
        superkey.enable = true;
        programs.pjones.emacsrc.enable = true;

        # Enable waybar debugging:
        # GTK_DEBUG = "interactive"; # Styling waybar.
        systemd.user.services.waybar.Service.ExecStart =
          lib.mkForce (waybarWrapper config);
      };
    };
  };
}
