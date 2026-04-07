{
  target = {
    platform = "linux";
    arch = "x86_64";
  };

  hardware = "asus-tianxuan4";
  locale = "zh-CN";

  capabilities = [
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
    "gaming/base"
  ];

  users.rikki = import ./users/rikki/meta.nix;

  overrides = {
    kaguya.services.docker.storageDriver = "btrfs";
  };
}
