{
  networking.hostName = "laptop-asus-tx4-personal";

  systemConfig = {
    architecture = "x86_64-linux";
    hardware = "asus-tianxuan4";

    users = {
      rikki.profiles = [
        "development"
        "software"
        "gaming"
        "business"
        "lifetime"
      ];
    };

    modules = [
      "desktop/gnome"
      "services/docker"
      "services/flatpak"
      "services/vm"
      "services/tailscale"
      "services/cups"
      "core/fonts"
      "core/input"
      "development/base"
      "development/emacs"
    ];
  };

  # 系统级配置
  time.timeZone = "Asia/Shanghai";

  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        3000
        8080
        20171
      ];
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "rikki"
    ];
  };

  system.stateVersion = "24.05";
}
