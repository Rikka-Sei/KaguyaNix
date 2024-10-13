{lib, ...}: {
  services.flatpak.enable = true;
  services.flatpak.remotes = lib.mkOptionDefault [
    {
      name = "flathub";
      location = "https://mirror.sjtu.edu.cn/flathub";
    }
  ];

  services.flatpak.packages = [
    "ar.xjuan.Cambalache"
    "com.getpostman.Postman"
    "com.github.gmg137.netease-cloud-music-gtk"
    "com.google.Chrome"
    "com.obsproject.Studio"
    "com.qq.QQ"
    "com.tencent.WeChat"
    "com.usebottles.bottles"
    "com.valvesoftware.Steam"
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
    "com.belmoussaoui.Authenticator" # Authenticator 身份验证器
    "com.usebottles.bottles"
    "com.github.tchx84.Flatseal"
  ];
}
