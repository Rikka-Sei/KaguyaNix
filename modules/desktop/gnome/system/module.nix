{ config, lib, pkgs, ... }:
let
  cfg = config.kaguya.desktop.gnome;
in
{
  options.kaguya.desktop.gnome.enable = lib.mkEnableOption "GNOME 桌面能力";

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    services.xserver.desktopManager.gnome.sessionPath = with pkgs; [
      mutter
      gnome-shell
    ];

    programs.kdeconnect = {
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };

    environment.systemPackages = with pkgs; [
      gnomeExtensions.appindicator
      gnomeExtensions.gtile
      gnomeExtensions.kimpanel
      gnomeExtensions.notification-banner-reloaded
      gnomeExtensions.places-status-indicator
      gnome-tweaks
      adwaita-icon-theme
    ];

    services.udev.packages = with pkgs; [ gnome-settings-daemon ];
  };
}
