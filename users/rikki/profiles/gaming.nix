{pkgs, ...}: let
  userName = "rikki";
in {
  # 游戏相关包
  environment.systemPackages = with pkgs; [
    steam
    mangohud
    gamemode
  ];

  # Steam 配置
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # 游戏性能优化
  programs.gamemode.enable = true;

  home-manager.users.${userName} = {
    # 游戏相关的 Home Manager 配置
    home.packages = with pkgs; [
      discord
      obs-studio
    ];
  };
}
