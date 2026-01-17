{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.superkey;
in
{
  options.superkey = {
    enable = lib.mkEnableOption "Enable Wayland configuration.";
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      restart = true;

      settings.default_session = {
        command = "${pkgs.greetd}/bin/agreety --cmd niri-session";
      };
    };

    xdg.portal = {
      enable = lib.mkDefault true;
      configPackages = [ pkgs.niri ];
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    };

    # Needed so swayidle can start when systemd locks/sleeps.
    services.systemd-lock-handler.enable = true;

    # https://github.com/NixOS/nixpkgs/issues/158025
    security.pam.services.hyprlock = { };

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
    services.dbus.packages = [
      pkgs.dconf
      pkgs.sushi
    ];

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
        iosevka
        overpass
        pjones.nerd-hyperlegible # From ../pkgs/nerd-hyperlegible.nix
        tt2020
      ];
    };

    # Enable the Home Manager module too:
    home-manager.users.pjones =
      { ... }:
      {
        superkey.enable = true;
      };
  };
}
