{ self }:

{ lib, pkgs, modulesPath, ... }:
let
  waybarWrapper = home: pkgs.writeShellScript "waybar-wrapper" ''
    # Enable waybar debugging:
    # export GTK_DEBUG="interactive"
    ${home.programs.waybar.package}/bin/waybar -l debug
  '';
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
    (import ./common.nix { inherit self; })
  ];

  config = {
    networking.hostName = "superkey";
    networking.networkmanager.enable = true;
    time.timeZone = lib.mkDefault "America/Phoenix";

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

    security.sudo.wheelNeedsPassword = false;
    services.openssh.enable = true;
    services.qemuGuest.enable = true;

    home-manager.users.pjones = { config, ... }: {
      systemd.user.services.waybar.Service.ExecStart =
        lib.mkForce (waybarWrapper config);
    };
  };
}
