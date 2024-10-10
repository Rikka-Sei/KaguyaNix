{pkgs, ...}: let
  trackerList = import ./aria2-tracker;
in {
  home.packages = with pkgs; [
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
      export TL=${trackerList}

      # ble.sh loader
      source "$(blesh-share)"/ble.sh --attach=none # does not work currently
      [[ ! $\{BLE_VERSION-\} ]] || ble-attach

      0file() { curl -F"file=@$1" https://envs.sh ; }
      0pb() { curl -F"file=@-;" https://envs.sh ; }
      0url() { curl -F"url=$1" https://envs.sh ; }
      0short() { curl -F"shorten=$1" https://envs.sh ; }
    '';

    shellAliases = {
      nixos-update = ''
        sudo systemctl stop nixos-rebuild-switch-to-configuration.service
        sudo nixos-rebuild switch --flake /home/rikki/WorkSpace/Dev/NixOS-Config/#ASUS_TianXuan4_Rikki
      '';
    };
  };
}
