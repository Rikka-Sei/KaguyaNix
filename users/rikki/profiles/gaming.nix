{ pkgs, lib, ... }:
let
  userName = "rikki";
in
{
  # Linux 特有的游戏相关包
  environment.systemPackages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    steam
    mangohud
    gamemode
  ]);

  # Steam 配置 - 仅限 Linux
  programs.steam = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # 游戏性能优化 - 仅限 Linux
  programs.gamemode.enable = lib.mkIf pkgs.stdenv.isLinux true;

  home-manager.users.${userName} = {
    # 跨平台游戏工具
    home.packages = with pkgs; [
      obs-studio
    ]
    # Linux 特有的游戏
    ++ lib.optionals pkgs.stdenv.isLinux [
      osu-lazer-bin
      hmcl
    ];
  };
}
