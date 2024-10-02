{
  config,
  pkgs,
  lib,
  ...
}: {
  home.username = "rikki";
  home.homeDirectory = "/home/rikki";
  nixpkgs.config.allowUnfree = true;

  # 直接将当前文件夹的配置文件，链接到 Home 目录下的指定位置
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # 递归将某个文件夹中的文件，链接到 Home 目录下的指定位置
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # 递归整个文件夹
  #   executable = true;  # 将其中所有文件添加「执行」权限
  # };

  # 直接以 text 的方式，在 nix 配置文件中硬编码文件内容
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # 设置鼠标指针大小以及字体 DPI（适用于 4K 显示器）
  #xresources.properties = {
  #  "Xcursor.size" = 16;
  #  "Xft.dpi" = 172;
  #};

  # git 相关配置
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "HenryZeng";
    userEmail = "zengdeveloper@qq.com";
  };

  # 通过 home.packages 安装一些常用的软件
  # 这些软件将仅在当前用户下可用，不会影响系统级别的配置
  # 建议将所有 GUI 软件，以及与 OS 关系不大的 CLI 软件，都通过 home.packages 安装
  home.packages = with pkgs;
    [
      # User Cli Tools
      neofetch
    ]
    ++ [
      # Gnome pkgs
      gnome.gnome-software
    ]
    ++ [
      # User GUI Tools
      gimp
      typora
    ]
    ++ [
      # Games
      hmcl
      mindustry
    ]
    ++ [
      # Web Browser
      firefox
    ]
    ++ [
      # editor
      vscode
    ]
    ++ [
      # Learn
      anki
    ]
    ++ [
      # File Transfer
      filezilla
    ]
    ++ [
      # Generater
      typst
    ]
    ++ [ 
      # TODO : waiting for new merge
      blesh
    ];

  # 启用 starship，这是一个漂亮的 shell 提示符
  programs.starship = {
    enable = true;
    # 自定义配置
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[x](bold red)";
        vimcmd_symbol = "[<](bold green)";
      };
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
      
      # ble.sh loader
      source "$(blesh-share)"/ble.sh --attach=none # does not work currently
      [[ ! $\{BLE_VERSION-\} ]] || ble-attach
    '';

    shellAliases = {
      nixos-update = ''
        sudo systemctl stop nixos-rebuild-switch-to-configuration.service
        sudo nixos-rebuild switch --flake /home/rikki/WorkSpace/Dev/NixOS-Config/#ASUS_TianXuan4_Rikki
      '';
    };
  };

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
