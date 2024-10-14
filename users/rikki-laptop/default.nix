{
  config,
  pkgs,
  lib,
  alejandra,
  ...
}: let
  userName = "rikki";
  stateVersion = "24.05";
in {
  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = ["wheel" "vboxusers"];
    shell = pkgs.fish;
  };

  home-manager.users.${userName} = {
    home.username = "${userName}";
    home.homeDirectory = "/home/${userName}";

    nixpkgs.config.allowUnfree = true;

    programs.git = {
      enable = true;
      lfs.enable = true;
      userName = "HenryZeng";
      userEmail = "zengdeveloper@qq.com";
    };

    imports = [
      # layers
      ./layer/software
      ./layer/shell

      # plugin
      ./plugin/alejandra
    ];

    home.stateVersion = "${stateVersion}";
    programs.home-manager.enable = true;
  };
}
