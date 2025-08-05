{
  pkgs,
  inputs,
  ...
}: let
  userName = "rikki";
in {
  # 开发工具
  environment.systemPackages = [
    inputs.alejandra.defaultPackage.${pkgs.system}
    inputs.nil.packages.${pkgs.system}.default
  ];

  # nix-ld 支持
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # 常用的动态库
      stdenv.cc.cc
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
    ];
  };

  home-manager.users.${userName} = {
    # Home Manager 开发环境配置
    programs.git = {
      enable = true;
      lfs.enable = true;
      userName = "Rikki";
      userEmail = "rikki@member.fsf.org";
      extraConfig = {
        user.signingkey = "85E52EEE42578D11";
        commit.gpgsign = true;
      };
    };

    programs.fish = {
      enable = true;
      shellAliases = {
        "0file" = "curl -F\"file=@$1\" https://envs.sh";
        "0pb" = "curl -F\"file=@-;\" https://envs.sh";
        "0url" = "curl -F\"url=$1\" https://envs.sh";
        "0short" = "curl -F\"shorten=$1\" https://envs.sh";
      };
    };

    programs.starship.enable = true;
  };

  users.users.${userName}.shell = pkgs.fish;
  programs.fish.enable = true;
}
