{
  config,
  pkgs,
  lib,
  alejandra,
  ...
} @ upstream: let
  userName = "rikki";
  stateVersion = "24.05";
  # userShell = import ./shell {inherit upstream;} // {userName = userName;};
in {
  imports = [
  ];

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
    ];

    home.stateVersion = "${stateVersion}";
    programs.home-manager.enable = true;
  };
}
