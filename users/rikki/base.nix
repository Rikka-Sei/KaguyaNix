{
  pkgs,
  inputs,
  lib,
  ...
}: let
  userName = "rikki";
  stateVersion = "24.05";
  # 根据系统平台确定 home 目录
  homeDirectory = if pkgs.stdenv.isDarwin 
                  then "/Users/${userName}"
                  else "/home/${userName}";
in {
  # Home Manager 基础配置
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };

  home-manager.users.${userName} = {
    home.username = "${userName}";
    home.homeDirectory = homeDirectory;
    home.stateVersion = "${stateVersion}";
    programs.home-manager.enable = true;
  };
}
