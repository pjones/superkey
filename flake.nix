{
  description = "Peter's Wayland Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    emacsrc.url = "github:pjones/emacsrc/nixos-25.11";
    emacsrc.inputs.nixpkgs.follows = "nixpkgs";
    emacsrc.inputs.home-manager.follows = "home-manager";

    org-clock-dbus.url = "github:pjones/org-clock-dbus";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      # What state version to use for the VM:
      stateVersion = "24.11";

      # List of supported systems:
      supportedSystems = [ "x86_64-linux" ];

      # Function to generate a set based on supported systems:
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Attribute set of nixpkgs for each system:
      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        }
      );
    in
    {
      ##########################################################################
      overlays = {
        superkey =
          final: prev:
          let
            system = prev.stdenv.hostPlatform.system;
          in
          {
            org-clock-dbus = self.inputs.org-clock-dbus.packages.${system}.monitor;

            pjones = (prev.pjones or { }) // {
              avatar = self.packages.${system}.pjones-avatar;
              nerd-hyperlegible = self.packages.${system}.nerd-hyperlegible;
              presenter-mode = self.packages.${system}.presenter-mode;
              rofirc = self.packages.${system}.rofirc;
              superkey-scripts = self.packages.${system}.superkey-scripts;
            };
          };
      };

      ##########################################################################
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          force-lock = pkgs.callPackage pkgs/force-lock { };
          nerd-hyperlegible = pkgs.callPackage pkgs/nerd-hyperlegible.nix { };

          pjones-avatar = pkgs.callPackage pkgs/pjones-avatar.nix { };
          presenter-mode = pkgs.callPackage pkgs/presenter-mode { };

          rofirc = pkgs.callPackage pkgs/rofirc {
            superkey-scripts = self.packages.${system}.superkey-scripts;
          };

          superkey-scripts = pkgs.callPackage pkgs/scripts { };

          theme-dracula = pkgs.callPackage pkgs/theme { colors = pkgs/theme/dracula.json; };

          theme-outrun = pkgs.callPackage pkgs/theme { colors = pkgs/theme/outrun.json; };

          niri-vm = self.nixosConfigurations.niri-vm.config.system.build.vm;

          xwininfo-tests = pkgs.writeShellApplication {
            name = "xwininfo";
            runtimeInputs = with pkgs; [
              jq
            ];
            text = builtins.readFile ./support/scripts/xwininfo-tests;
          };
        }
      );

      ##########################################################################
      apps = forAllSystems (system: {
        # Launch a VM running Peter's configuration:
        default = self.apps.${system}.niri;

        # Run Niri in a VM:
        niri = {
          type = "app";
          meta.description = "Run Niri in a VM";
          program = "${self.packages.${system}.niri-vm}/bin/run-superkey-vm";
        };

        # Run a VM then take a screenshot and store it locally:
        # screenshot =
        #   let
        #     script = pkgs.writeShellScript "screenshot" ''
        #       cp --force ${self.checks.${system}.niri}/*.png support/
        #     '';
        #   in
        #   {
        #     type = "app";
        #     meta.description = "Take a screenshot of a Niri VM";
        #     program = "${script}";
        #   };
        #
        # # Interactive version of the Niri test:
        # niriTest = {
        #   type = "app";
        #   meta.description = "Interactively debug a Niri session";
        #   program = "${self.checks.${system}.niri.driverInteractive}/bin/nixos-test-driver";
        # };
      });

      ##########################################################################
      nixosConfigurations =
        let
          vmBase =
            module:
            nixpkgs.lib.nixosSystem {
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
        };

      ##########################################################################
      nixosModules = {
        default = {
          imports = [ ./nixos ];
        };

        # A virtual machine running Niri:
        niri-vm = {
          imports = [ (import test/vm.nix { inherit self; }) ];

          virtualisation.qemu.options = [
            "-spice port=0,disable-ticketing=on,image-compression=off,gl=on,rendernode=/dev/dri/by-path/pci-0000:c1:00.0-render,seamless-migration=on"
            "-device virtio-vga-gl,id=video0,max_outputs=1"
            "-display spice-app,gl=on"
          ];
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
        default =
          { pkgs, ... }:
          {
            imports = [ ./home ];

            superkey = {
              theme = self.packages.${pkgs.stdenv.hostPlatform.system}.theme-outrun;

              swaylock =
                let
                  lockBin = "${self.packages.${pkgs.stdenv.hostPlatform.system}.force-lock}/bin";
                in
                {
                  forceLockCmd = "${lockBin}/force-lock.sh";
                  stopAllInhibitorsCmd = "${lockBin}/stop-idle-inhibitors.sh";
                  startAllInhibitorsCmd = "${lockBin}/start-idle-inhibitors.sh";
                };
            };
          };

        vm =
          { ... }:
          {
            imports = [
              { home.stateVersion = stateVersion; }
              self.homeManagerModules.default
            ];
          };
      };

      ##########################################################################
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          #niri = import test/niri.nix { inherit pkgs self; };
          greetd = import test/greetd.nix { inherit pkgs self; };
        }
      );

      ##########################################################################
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            NIX_PATH = "nixpkgs=${pkgs.path}";

            buildInputs = [
              pkgs.fastfetch
              pkgs.nixpkgs-fmt
            ];
          };
        }
      );
    };
}
