{
  description = "Peter's Wayland Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    emacsrc.url = "github:pjones/emacsrc/nixos-25.05";
    emacsrc.inputs.nixpkgs.follows = "nixpkgs";
    emacsrc.inputs.home-manager.follows = "home-manager";

    sway-easyfocus.url = "github:pjones/sway-easyfocus/pjones/swap";
    sway-easyfocus.flake = false;

    org-clock-dbus.url = "github:pjones/org-clock-dbus";
  };

  outputs = { self, nixpkgs, ... }:
    let
      # What state version to use for the VM:
      stateVersion = "24.11";

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
          org-clock-dbus = self.inputs.org-clock-dbus.packages.${prev.system}.monitor;

          pjones = (prev.pjones or { }) // {
            avatar = self.packages.${prev.system}.pjones-avatar;
            nerd-hyperlegible = self.packages.${prev.system}.nerd-hyperlegible;
            presenter-mode = self.packages.${prev.system}.presenter-mode;
            rofirc = self.packages.${prev.system}.rofirc;
            superkey-scripts = self.packages.${prev.system}.superkey-scripts;
          };

          sway-easyfocus = prev.sway-easyfocus.overrideAttrs (orig: {
            version = builtins.substring 0 7 self.inputs.sway-easyfocus;
            src = self.inputs.sway-easyfocus;
            cargoDeps = prev.rustPlatform.fetchCargoVendor {
              src = self.inputs.sway-easyfocus;
              hash = "sha256-VxcMHh1eIiHugpTFpclwuO0joY95bPz6hVIBHQwB6ZA=";
            };
          });
        };
      };

      ##########################################################################
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          force-lock = pkgs.callPackage pkgs/force-lock { };
          nerd-hyperlegible = pkgs.callPackage pkgs/nerd-hyperlegible.nix { };

          pjones-avatar = pkgs.callPackage pkgs/pjones-avatar.nix { };
          presenter-mode = pkgs.callPackage pkgs/presenter-mode { };

          rofirc = pkgs.callPackage pkgs/rofirc {
            rofi = pkgs.rofi-wayland;
            superkey-scripts = self.packages.${system}.superkey-scripts;
          };

          superkey-scripts = pkgs.callPackage pkgs/scripts { };

          theme-dracula = pkgs.callPackage pkgs/theme {
            colors = pkgs/theme/dracula.json;
          };

          theme-outrun = pkgs.callPackage pkgs/theme {
            colors = pkgs/theme/outrun.json;
          };

          niri-vm = self.nixosConfigurations.niri-vm.config.system.build.vm;
          sway-vm = self.nixosConfigurations.sway-vm.config.system.build.vm;

          xwininfo-tests = pkgs.writeShellApplication {
            name = "xwininfo";
            runtimeInputs = with pkgs; [ jq swayfx ];
            text = builtins.readFile ./support/scripts/xwininfo-tests;
          };
        });

      ##########################################################################
      apps = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          # Launch a VM running Peter's configuration:
          default = self.apps.${system}.sway;

          # Run Niri in a VM:
          niri = {
            type = "app";
            program = "${self.packages.${system}.niri-vm}/bin/run-superkey-vm";
          };

          # Run Sway in a VM:
          sway = {
            type = "app";
            program = "${self.packages.${system}.sway-vm}/bin/run-superkey-vm";
          };

          # Run a VM then take a screenshot and store it locally:
          screenshot =
            let
              script = pkgs.writeShellScript "screenshot" ''
                cp --force ${self.checks.${system}.sway}/*.png support/
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
      nixosConfigurations =
        let
          vmBase = module: nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              { nixpkgs.pkgs = nixpkgsFor.x86_64-linux; }
              { system.stateVersion = stateVersion; }
              self.nixosModules.${module}
            ];
          };
        in
        {
          niri-vm = vmBase "niri-vm";
          sway-vm = vmBase "sway-vm";
        };

      ##########################################################################
      nixosModules = {
        default = {
          imports = [
            ./nixos
          ];
        };

        # A virtual machine running Niri:
        niri-vm = {
          imports = [
            (import test/vm.nix { inherit self; })
          ];

          superkey.compositor = "niri";

          virtualisation.qemu.options = [
            "-spice port=0,disable-ticketing=on,image-compression=off,gl=on,rendernode=/dev/dri/by-path/pci-0000:c1:00.0-render,seamless-migration=on"
            "-device virtio-vga-gl,id=video0,max_outputs=1"
            "-display spice-app,gl=on"
          ];
        };

        # A virtual machine running Sway:
        sway-vm = {
          imports = [
            (import test/vm.nix { inherit self; })
          ];

          superkey.compositor = "sway";
        };

        # Helpful for other flakes:
        autologin = import test/autologin.nix;
        qemu-wayland = import test/qemu-wayland.nix;

        # Per-host configuration:
        falken = import devices/sid.nix;
        sid = import devices/sid.nix;
      };

      ##########################################################################
      homeManagerModules = {
        default = { pkgs, ... }: {
          imports = [
            ./home
          ];

          superkey = {
            theme = self.packages.${pkgs.system}.theme-outrun;

            swaylock =
              let
                lockBin = "${self.packages.${pkgs.system}.force-lock}/bin";
              in
              {
                forceLockCmd = "${lockBin}/force-lock.sh";
                stopAllInhibitorsCmd = "${lockBin}/stop-idle-inhibitors.sh";
                startAllInhibitorsCmd = "${lockBin}/start-idle-inhibitors.sh";
              };
          };
        };

        vm = { ... }: {
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
          niri = import test/niri.nix { inherit pkgs self; };
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
