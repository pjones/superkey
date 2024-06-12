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
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        });
    in
    {
      overlays = {
        desktop-scripts = self.inputs.desktop-scripts.overlays.desktop-scripts;
        rofirc = self.inputs.rofirc.overlays.default;
      };

      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          vm = self.nixosConfigurations.vm.config.system.build.vm;
          dracula = pkgs.callPackage pkgs/dracula { };
        });

      nixosModules = {
        default = { pkgs, ... }: {
          programs.sway = {
            enable = true;
            package = null;
          };

          # Needed so swayidle can start when systemd locks/sleeps.
          services.systemd-lock-handler.enable = true;

          services.pipewire.enable = true;
          services.pipewire.pulse.enable = true;
          services.pipewire.alsa.enable = true;

          environment.systemPackages = with pkgs; [
            adwaita-qt # A style to bend Qt applications to look like they belong into GNOME Shell
            adwaita-qt6 # A style to bend Qt applications to look like they belong into GNOME Shell
            gnome.gnome-themes-extra # Dark theme
            qt5.qtwayland # Qt5 support for Wayland.
          ];

          environment.pathsToLink = [
            "/share/xdg-desktop-portal"
            "/share/applications"
          ];
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

          superkey.theme =
            self.packages.${pkgs.system}.dracula;
        };

        vm = { pkgs, ... }: {
          imports = [
            { home.stateVersion = stateVersion; }
            self.homeManagerModules.default
          ];

          programs.waybar.package =
            self.inputs.waybar.packages.${pkgs.system}.default;
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
