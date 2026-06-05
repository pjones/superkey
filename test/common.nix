{ self }:

{ pkgs, ... }:

{
  imports = [
    self.inputs.home-manager.nixosModules.home-manager
    self.nixosModules.default
    ./qemu-wayland.nix
  ];

  config = {
    users.users.pjones = {
      isNormalUser = true;
      uid = 1000;
      password = "password";
      extraGroups = [
        "wheel"
        "video"
        "render"
      ];
    };

    # Enable NixOS settings:
    superkey.enable = true;

    # Make sure test scripts are installed:
    environment.systemPackages = [ (pkgs.callPackage ./test-scripts.nix { }) ];

    # Enable Home Manager settings:
    home-manager = {
      backupFileExtension = "backup";
      useGlobalPkgs = true;
      useUserPackages = true;

      users.pjones =
        { ... }:
        {
          imports = [
            self.homeManagerModules.vm
            self.inputs.emacsrc.homeModules.emacsrc
          ];

          home.username = "pjones";
          home.homeDirectory = "/home/pjones";
          superkey.primaryOutput = "Virtual-1";
        };
    };
  };
}
