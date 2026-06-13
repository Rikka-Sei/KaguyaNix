{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.feishu;
in {
  options.kaguya.software.feishu.enable = lib.mkEnableOption "feishu 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.feishu];
  };
}
