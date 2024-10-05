{pkgs, ...}: {
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  services.xserver.desktopManager.gnome.sessionPath = with pkgs; [
    gnome.mutter
    gnome.gnome-shell
  ];

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.gtile
    gnomeExtensions.kimpanel
    gnome.adwaita-icon-theme
  ];

  services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];
}
