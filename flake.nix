{
  description = "Peter's Wayland Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    waybar.url = "github:Alexays/Waybar";

    emacsrc.url = "github:pjones/emacsrc/nixos-24.05";
    emacsrc.inputs.nixpkgs.follows = "nixpkgs";
    emacsrc.inputs.home-manager.follows = "home-manager";

    desktop-scripts.url = "github:pjones/desktop-scripts";
    desktop-scripts.inputs.nixpkgs.follows = "nixpkgs";

    rofirc.url = "github:pjones/rofirc/wayland";
    rofirc.inputs.nixpkgs.follows = "nixpkgs";
    rofirc.inputs.desktop-scripts.follows = "desktop-scripts";

    sway-easyfocus.url = "github:pjones/sway-easyfocus/pjones/swap";
    sway-easyfocus.flake = false;
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # What state version to use for the VM:
      stateVersion = "24.05";

      # List of supported systems:
      supportedSystems = [
        "x86_64-linux"
      ];

      # Function to generate a set based on supported systems:
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Attribute set of nixpkgs for each system:
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        });
    in
    {
      ##########################################################################
      overlays = {
        superkey = final: prev: {
          pjones = (prev.pjones or { }) // {
            desktop-scripts = self.inputs.desktop-scripts.packages.${prev.system}.desktop-scripts;
            rofirc-wayland = self.inputs.rofirc.packages.${prev.system}.rofirc-wayland;
          };

          sway-easyfocus = prev.sway-easyfocus.overrideAttrs (orig: rec {
            version = "unstable-2024-07-08";
            src = self.inputs.sway-easyfocus;
            cargoDeps = orig.cargoDeps.overrideAttrs {
              inherit src;
              name = "${orig.pname}-${version}-vendor.tar.gz";
              outputHash = "sha256-Aiells9F2ZuCzQ7T9l2Y8k6iNvQAfIzWL98NZ1AHkLo=";
            };
          });
        };
      };

      ##########################################################################
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          vm = self.nixosConfigurations.vm.config.system.build.vm;
          force-lock = pkgs.callPackage pkgs/force-lock { };

          theme-dracula = pkgs.callPackage pkgs/theme {
            colors = pkgs/theme/dracula.json;
          };

          theme-outrun = pkgs.callPackage pkgs/theme {
            colors = pkgs/theme/outrun.json;
          };
        });

      ##########################################################################
      apps = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          # Launch a VM running Peter's configuration:
          default = {
            type = "app";
            program = "${self.packages.${system}.vm}/bin/run-superkey-vm";
          };

          # Run a VM then take a screenshot and store it locally:
          screenshot =
            let
              script = pkgs.writeShellScript "screenshot" ''
                cp --force \
                  ${self.checks.${system}.sway}/screen.png \
                  support/screenshot.png
              '';
            in
            {
              type = "app";
              program = "${script}";
            };

          # Interactive version of the sway test:
          swayTest = {
            type = "app";
            program = "${self.checks.${system}.sway.driverInteractive}/bin/nixos-test-driver";
          };
        });

      ##########################################################################
      nixosConfigurations = {
        vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            { nixpkgs.pkgs = nixpkgsFor.x86_64-linux; }
            { system.stateVersion = stateVersion; }
            self.nixosModules.vm
          ];
        };
      };

      ##########################################################################
      nixosModules = {
        default = {
          imports = [
            self.inputs.desktop-scripts.nixosModules.default
            ./nixos
          ];
        };

        # VM related:
        vm = import test/vm.nix { inherit self; };
        autologin = import test/autologin.nix;
        qemu-sway = import test/qemu-sway.nix;

        # Per-host configuration:
        jekyll = import devices/jekyll.nix;
        medusa = import devices/medusa.nix;
      };

      ##########################################################################
      homeManagerModules = {
        default = { pkgs, ... }: {
          imports = [
            self.inputs.desktop-scripts.homeManagerModules.default
            ./home
          ];

          superkey = {
            theme = self.packages.${pkgs.system}.theme-outrun;

            swaylock.forceLockCmd =
              "${self.packages.${pkgs.system}.force-lock}/bin/force-lock.sh";
          };

          programs.waybar.package =
            self.inputs.waybar.packages.${pkgs.system}.default;
        };

        vm = { pkgs, ... }: {
          imports = [
            { home.stateVersion = stateVersion; }
            self.homeManagerModules.default
          ];
        };
      };

      ##########################################################################
      checks = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          sway = import test/sway.nix { inherit pkgs self; };
          greetd = import test/greetd.nix { inherit pkgs self; };
        });

      ##########################################################################
      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in
        {
          default = pkgs.mkShell {
            NIX_PATH = "nixpkgs=${pkgs.path}";

            buildInputs = [
              pkgs.fastfetch
              pkgs.nixpkgs-fmt
            ];
          };
        });
    };
}
