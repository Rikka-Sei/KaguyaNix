{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.gaming.steam;
in {
  options.kaguya.gaming.steam.enable = lib.mkEnableOption "Steam 游戏平台能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.steam];
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };
}
