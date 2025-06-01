{ config, lib, pkgs, ... }:

let
  cfg = config.superkey;
in
{
  options.superkey = {
    enable = lib.mkEnableOption "Enable Wayland configuration.";

    compositor = lib.mkOption {
      type = lib.types.enum [ "niri" "sway" ];
      default = "sway";
      description = "The name of the compositor to use";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      restart = true;

      settings.default_session =
        let
          cmd =
            if cfg.compositor == "sway"
            then "sway"
            else if cfg.compositor == "niri"
            then "niri-session"
            else "bash";
        in
        {
          command = "${pkgs.greetd.greetd}/bin/agreety --cmd ${cmd}";
        };
    };

    # NixOS requires special configuration for Wayland that is done in
    # one of the compositor modules.  We set the `package` option to
    # `null` so that the compositor isn't installed in the system
    # path.
    programs.sway = lib.mkIf (cfg.compositor == "sway") {
      enable = true;
      package = null;
      extraPackages = [ ];
    };

    xdg.portal = lib.mkIf (cfg.compositor != "sway") {
      enable = lib.mkDefault true;
      configPackages = [ pkgs.niri ];
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    };

    # Needed so swayidle can start when systemd locks/sleeps.
    services.systemd-lock-handler.enable = true;

    # https://github.com/NixOS/nixpkgs/issues/158025
    security.pam.services.swaylock = { };

    # Sound:
    services.pipewire.enable = true;
    services.pipewire.pulse.enable = true;
    services.pipewire.alsa.enable = true;

    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    # Packages to install:
    environment.systemPackages = [
      pkgs.adwaita-icon-theme # Adwaita icon them
      pkgs.adwaita-qt # A style to bend Qt applications to look like they belong into GNOME Shell
      pkgs.adwaita-qt6 # A style to bend Qt applications to look like they belong into GNOME Shell
      pkgs.gnome-themes-extra # Dark theme
      pkgs.pjones.avatar # For tools that use an avatar
      pkgs.qt5.qtwayland # Qt5 support for Wayland.
    ];

    # System services that need to be running:
    services.udisks2.enable = true;

    # For setting GTK themes:
    programs.dconf.enable = true;
    services.dbus.packages = [ pkgs.dconf pkgs.sushi ];

    # Fonts:
    fonts = {
      fontconfig.enable = true;
      fontDir.enable = true;
      enableGhostscriptFonts = true;
      packages = with pkgs; [
        atkinson-hyperlegible
        dejavu_fonts
        hermit
        ibm-plex
        overpass
        pjones.nerd-hyperlegible # From ../pkgs/nerd-hyperlegible.nix
        tt2020
        ubuntu_font_family
      ];
    };

    # Enable the Home Manager module too:
    home-manager.users.pjones = { ... }: {
      superkey.enable = true;
      superkey.compositor = lib.mkDefault cfg.compositor;
    };
  };
}
