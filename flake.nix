{
  description = "Peter's SwayFX Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    emacsrc.url = "github:pjones/emacsrc/nixos-24.05";
    emacsrc.inputs.nixpkgs.follows = "nixpkgs";
    emacsrc.inputs.home-manager.follows = "home-manager";

    catppuccin.url = "github:catppuccin/i3";
    catppuccin.flake = false;
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # What state version to use for the VM:
      stateVersion = "24.05";

      # List of supported systems:
      supportedSystems = nixpkgs.lib.platforms.unix;

      # Function to generate a set based on supported systems:
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Attribute set of nixpkgs for each system:
      nixpkgsFor = forAllSystems (system:
        import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          vm = self.nixosConfigurations.vm.config.system.build.vm;

          catppuccin = pkgs.callPackage pkgs/catppuccin {
            src = self.inputs.catppuccin;
          };

          dracula = pkgs.callPackage pkgs/dracula { };
        });

      nixosModules = {
        default = { pkgs, ... }: {
          programs.sway = {
            enable = true;
            package = pkgs.swayfx.override { isNixOS = true; };
          };
        };

        vm = import test/vm.nix { inherit self; };
      };

      nixosConfigurations = {
        vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            { nixpkgs.pkgs = nixpkgsFor.x86_64-linux; }
            { system.stateVersion = stateVersion; }
            self.nixosModules.vm
            self.nixosModules.default
          ];
        };
      };

      homeManagerModules = {
        default = { pkgs, ... }: {
          imports = [
            ./home
          ];

          programs.pjones.swayfx.theme =
            self.packages.${pkgs.system}.dracula;
        };

        vm = { ... }: {
          imports = [
            { home.stateVersion = stateVersion; }
            self.homeManagerModules.default
          ];
        };
      };

      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in
        {
          default = pkgs.mkShell {
            NIX_PATH = "nixpkgs=${pkgs.path}";

            buildInputs = [
              pkgs.neofetch
              pkgs.nixpkgs-fmt
            ];
          };
        });
    };
}
