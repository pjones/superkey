{ self }:

{ ... }:

{
  imports = [
    self.inputs.home-manager.nixosModules.home-manager
    self.nixosModules.default
    ./qemu-sway.nix
  ];

  config = {
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
      };
    };
  };
}
