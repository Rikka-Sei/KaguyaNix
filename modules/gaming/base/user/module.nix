{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kaguya.gaming.base;
in
{
  options.kaguya.gaming.base.enable = lib.mkEnableOption "基础游戏用户能力";

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        obs-studio
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        osu-lazer-bin
        hmcl
        mindustry
        ddnet
      ];
  };
}
