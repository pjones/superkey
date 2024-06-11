{ config, lib, ... }:

{
  config = lib.mkIf config.superkey.enable {
    services.swaync = {
      enable = true;

      settings = {
        widgets = [
          "inhibitors"
          "title"
          "dnd"
          "mpris"
          "notifications"
        ];

        widget-config = {
          inhibitors = {
            text = "Inhibitors";
            button-text = "Clear All";
            clear-all-button = true;
          };
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear All";
          };
          dnd = {
            text = "Do Not Disturb";
          };
          mpris = {
            image-size = 96;
            image-radius = 12;
          };
        };
      };
    };
  };
}
