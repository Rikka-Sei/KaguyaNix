{
  config,
  lib,
  ...
}: let
  cfg = config.kaguya.services.flatpak;
in {
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
      default = [];
      description = "Flatpak 默认安装列表。";
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    services.flatpak.remotes = lib.mkOptionDefault cfg.remotes;
    services.flatpak.packages = cfg.packages;
  };
}
