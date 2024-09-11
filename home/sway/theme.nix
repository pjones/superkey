{ lib, pkgs, config, ... }:

let
  cfg = config.superkey.sway;
  colors = config.superkey.theme.colors;

  rrggbb = color:
    builtins.substring 1 (builtins.stringLength color - 1) color;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        gaps.inner = 5;
        gaps.outer = 20;
        gaps.smartBorders = "off";
      };

      extraConfig = ''
        smart_gaps inverse_outer # Home Manager module broken.
        include ${config.superkey.theme}/theme/sway.cfg
      '';
    };

    xdg.configFile."sway-easyfocus/config.yaml".text = ''
      chars: 'fjghdkslaemuvitywoqpcbnxz'

      window_background_color: '000000'
      window_background_opacity: 0.0

      label_background_color: '${rrggbb colors.base0F}'
      label_background_opacity: 1.0
      label_text_color: '${rrggbb colors.base05}'

      focused_background_color: '${rrggbb colors.base00}'
      focused_background_opacity: 1.0
      focused_text_color: '${rrggbb colors.base03}'

      font_family: Hermit
      font_weight: bold
      font_size: 20pt

      label_padding_x: 4
      label_padding_y: 2
      label_margin_x: 4
      label_margin_y: 2
    '';
  };
}
