{
  pkgs,
  unstable,
  inputs,
  config,
  lib,
  ...
}:
let
  userName = "rikki";
  isDarwin = lib.arch.isDarwin config.systemConfig.architecture;

  # 自动扫描 scripts 目录下的所有 .sh 文件
  scriptsDir = ./scripts;
  scriptFiles = builtins.readDir scriptsDir;

  # 生成 home.file 配置，将每个 .sh 文件部署到 ~/.local/bin/
  # 文件名去掉 .sh 后缀，并设置为可执行
  deployScripts = lib.mapAttrs' (
    name: type:
    let
      # 去掉 .sh 后缀
      scriptName = lib.removeSuffix ".sh" name;
    in
    lib.nameValuePair ".local/bin/${scriptName}" {
      source = scriptsDir + "/${name}";
      executable = true;
    }
  ) (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".sh" name) scriptFiles);
in
{
  # 开发工具
  environment.systemPackages = [
    inputs.alejandra.defaultPackage.${pkgs.system}
    inputs.nil.packages.${pkgs.system}.default
  ];

  programs.AI-wrapper = {
    enable = true;
    package = unstable.AI-code;
  };

  home-manager.users.${userName} = {
    # 添加 ~/.local/bin 到 PATH
    home.sessionPath = [
      "$HOME/.local/bin"

      # curl -fsSL https://opencode.ai/install | bash
      # 需要安装 opencode
      "$HOME/.opencode/bin"
    ];

    # Home Manager 开发环境配置
    programs.git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user = {
          name = "Rikki";
          email = "rikki@member.fsf.org";
          signingkey = "3927D7F5365B0203";
        };
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
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';
    };

    # 自动部署 scripts 目录下的所有 bash 脚本到 ~/.local/bin/
    home.file = deployScripts;

    programs.starship.enable = true;
  };

  # Shell 配置
  users.users.${userName}.shell = pkgs.fish;
  programs.fish.enable = true;

  # macOS: 将 fish 添加到系统可用的 shell 列表
  # 这会更新 /etc/shells 文件，使 fish 成为合法的登录 shell
  environment.shells = if isDarwin then [ pkgs.fish ] else [ ];
}
