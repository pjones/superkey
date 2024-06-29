{ config, lib, pkgs, ... }:

{
  options.superkey = {
    enable = lib.mkEnableOption "Enable Wayland configuration.";
  };

  config = lib.mkIf config.superkey.enable {
    pjones.desktop-scripts.enable = true;

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
      extraPackages = [ ];
    };

    # Needed so swayidle can start when systemd locks/sleeps.
    services.systemd-lock-handler.enable = true;

    # Sound:
    services.pipewire.enable = true;
    services.pipewire.pulse.enable = true;
    services.pipewire.alsa.enable = true;

    environment.systemPackages = with pkgs; [
      qt5.qtwayland # Qt5 support for Wayland.
    ];

    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    # Enable the Home Manager module too:
    home-manager.users.pjones = { ... }: {
      superkey.enable = true;
    };
  };
}
