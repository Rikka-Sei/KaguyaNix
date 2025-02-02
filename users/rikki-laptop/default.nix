{ ... }:
let
  userName = "rikki";
  stateVersion = "24.05";
in
{
  user-shell.users.${userName} = {
    enable = true;
    defaultShell = "fish";
    bash.bashrcExtra = ''
      0file() { curl -F"file=@$1" https://envs.sh ; }
      0pb() { curl -F"file=@-;" https://envs.sh ; }
      0url() { curl -F"url=$1" https://envs.sh ; }
      0short() { curl -F"shorten=$1" https://envs.sh ; }
    '';
    languageServer = ["alejandra"];
  };

  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "vboxusers"
    ];
  };

  home-manager.users.${userName} = {
    home.username = "${userName}";
    home.homeDirectory = "/home/${userName}";

    nixpkgs.config.allowUnfree = true;

    imports = [
      # layers
      ./software

      # plugin
      ./plugin/git
    ];

    home.stateVersion = "${stateVersion}";
    programs.home-manager.enable = true;
  };
}
