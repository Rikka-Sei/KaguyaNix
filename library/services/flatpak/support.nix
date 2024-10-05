{lib, ...}: {
  services.flatpak.enable = true;
  services.flatpak.remotes = lib.mkOptionDefault [
    {
      name = "flathub";
      location = "https://mirror.sjtu.edu.cn/flathub";
    }
  ];
}
