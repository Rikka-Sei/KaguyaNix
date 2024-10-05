{
  home.packages = with pkgs;
    [ 
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
}