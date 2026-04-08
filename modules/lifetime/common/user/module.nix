{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.lifetime.common;
in {
  options.kaguya.lifetime.common.enable = lib.mkEnableOption "日常生活软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      spotify
    ];
  };
}
