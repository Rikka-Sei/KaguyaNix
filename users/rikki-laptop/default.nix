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
  user-shell.${userName}.defaultShell = "fish";

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = ["wheel" "vboxusers"];
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
      ./software

      # plugin
      ./plugin/alejandra
      ./plugin/git
    ];

    home.stateVersion = "${stateVersion}";
    programs.home-manager.enable = true;
  };
}
