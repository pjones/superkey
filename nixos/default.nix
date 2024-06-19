{ config, lib, pkgs, ... }:

{
  options.superkey = {
    enable = lib.mkEnableOption "Enable Wayland configuration.";
  };

  config = lib.mkIf config.superkey.enable {
    services.greetd = {
      enable = true;
      restart = true;

      settings.default_session = {
        command = "${pkgs.greetd.greetd}/bin/agreety --cmd sway";
      };
    };

    programs.sway = {
      enable = true;
      package = null;
    };

    # Needed so swayidle can start when systemd locks/sleeps.
    services.systemd-lock-handler.enable = true;

    # Sound:
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
}
