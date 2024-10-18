{
  pkgs,
  userName,
  ...
}: let
  trackerList = import ./aria2-tracker;
in {
  _module.args = {inherit trackerList;};

  imports = [
    ./fish
    ./bash
  ];

  options.userShell = {
    bash = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "enable bash";
      };
    };

    fish = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "enable bash";
      };
    };

    choose = mkOption {
      type = types.package;
      default = pkgs.bash;
      description = "to switch configs";
    };
  };

  config = mkIf config.myModule.enable {
    systemd.services.myService = {
      # 创建新的 systemd 服务
      wantedBy = ["multi-user.target"]; # 此服务希望在多用户目标下启动
      script = ''        # 服务启动时运行此脚本
                      echo "Hello, NixOS!"
      '';
    };
  };
}
