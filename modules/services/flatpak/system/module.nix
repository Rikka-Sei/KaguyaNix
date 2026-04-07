{ config, lib, ... }:
let
  cfg = config.kaguya.services.flatpak;
in
{
  options.kaguya.services.flatpak = {
    enable = lib.mkEnableOption "Flatpak 服务能力";
    remotes = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [
        {
          name = "flathub";
          location = "https://mirror.sjtu.edu.cn/flathub";
        }
      ];
      description = "Flatpak 远程仓库。";
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
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
      description = "Flatpak 默认安装列表。";
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    services.flatpak.remotes = lib.mkOptionDefault cfg.remotes;
    services.flatpak.packages = cfg.packages;
  };
}
