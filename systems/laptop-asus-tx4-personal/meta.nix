{
  target = {
    platform = "linux";
    arch = "x86_64";
  };

  hardware = "asus-tianxuan4";
  locale = "zh-CN";

  views = [
    "development/base"
    "gaming/base"
  ];

  caps = [
    "desktop/gnome"
    "services/docker"
    "services/flatpak"
    "services/vm"
    "services/tailscale"
    "services/cups"
    "core/fonts"
    "core/input"
    "development/emacs"
  ];

  users.rikki = import ./users/rikki/meta.nix;

  overrides = {
    kaguya.services.docker.storageDriver = "btrfs";
    kaguya.services.flatpak.packages = [
      "ar.xjuan.Cambalache"
      "com.google.Chrome"
      "com.obsproject.Studio"
      "com.valvesoftware.Steam"
      "com.tencent.WeChat"
      "dev.geopjr.Calligraphy"
      "org.gnome.Boxes"
      "org.gnome.Builder"
      "org.gnome.GHex"
      "org.inkscape.Inkscape"
      "org.kicad.KiCad"
      "org.libreoffice.LibreOffice"
      "org.octave.Octave"
      "org.qbittorrent.qBittorrent"
      "org.sdrangel.SDRangel"
      "org.telegram.desktop"
      "org.telegram.desktop.webview"
      "re.sonny.Workbench"
      "org.gnome.Fractal"
      "org.gnome.World.Secrets"
      "org.blender.Blender"
      "com.tencent.wemeet"
      "com.baidu.NetDisk"
      "io.github.Foldex.AdwSteamGtk"
      "org.gabmus.gfeeds"
      "com.belmoussaoui.Authenticator"
      "com.github.tchx84.Flatseal"
      "com.qq.QQ"
    ];
  };
}
