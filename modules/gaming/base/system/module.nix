{ config, lib, pkgs, ... }:
let
  cfg = config.kaguya.gaming.base;
in
{
  options.kaguya.gaming.base.enable = lib.mkEnableOption "基础游戏能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      steam
      mangohud
      gamemode
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    programs.gamemode.enable = true;
  };
}
