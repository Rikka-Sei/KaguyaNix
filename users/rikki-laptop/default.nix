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
  user-shell.${userName} = {
    enable = true;
    defaultShell = "fish";
    bashConf.bashrcExtra = ''
      0file() { curl -F"file=@$1" https://envs.sh ; }
      0pb() { curl -F"file=@-;" https://envs.sh ; }
      0url() { curl -F"url=$1" https://envs.sh ; }
      0short() { curl -F"shorten=$1" https://envs.sh ; }
    '';
  };

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = ["wheel" "vboxusers"];
  };

  home-manager.users.${userName} = {
    home.username = "${userName}";
    home.homeDirectory = "/home/${userName}";

    nixpkgs.config.allowUnfree = true;

    imports = [
      # layers
      ./software

      # plugin
      ./plugin/alejandra
      ./plugin/git
      ./plugin/gpg
    ];

    home.stateVersion = "${stateVersion}";
    programs.home-manager.enable = true;
  };
}
