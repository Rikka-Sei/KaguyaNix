{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.user-shell;

  shell-conf =
    name: value:
    let
      trackerList = import ../aria2-tracker;

      # inner cfg, helps function to locate specific configs
      icfg = value.bash;
    in
    {
      home.packages = with pkgs; [
        # TODO : waiting for new merge
        (mkIf (icfg.blesh.enable) blesh)
      ];

      # 启用 starship，这是一个漂亮的 shell 提示符
      programs.starship = {
        enable = icfg.starship.enable;
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
        bashrcExtra = concatLines [
          ''
            export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
            export TL=${trackerList}
          ''
          (
            if icfg.blesh.enable then
              ''
                # ble.sh loader
                source "$(blesh-share)"/ble.sh --attach=none # does not work currently
                [[ ! $\{BLE_VERSION-\} ]] || ble-attach
              ''
            else
              ""
          )
          icfg.bashrcExtra
        ];

        shellAliases = {
          nixos-update = ''
            sudo systemctl stop nixos-rebuild-switch-to-configuration.service
            sudo nixos-rebuild switch --flake /home/rikki/WorkSpace/Dev/NixOS-Config/#ASUS_TianXuan4_Rikki
          '';
        };
      };
    };

  isType = t: t == "bash";
  isSelected = v: v.enable && isType v.defaultShell;
in
{
  config = {
    home-manager.users = mapAttrs (name: v: mkIf (isSelected v) (shell-conf name v)) cfg;

    # users.users.<name>.shell = pkgs.bash;
    users.users = mapAttrs (_: v: mkIf (isSelected v) { shell = pkgs.bash; }) cfg;
  };
}
