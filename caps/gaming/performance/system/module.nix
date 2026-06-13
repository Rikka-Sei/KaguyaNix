{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.gaming.performance;
in {
  options.kaguya.gaming.performance.enable = lib.mkEnableOption "游戏性能工具能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mangohud
      gamemode
    ];
    programs.gamemode.enable = true;
  };
}
