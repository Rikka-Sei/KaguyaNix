{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.qq;
in {
  options.kaguya.software.qq.enable = lib.mkEnableOption "qq 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.qq];
  };
}
