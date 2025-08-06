{
  lib,
  pkgs,
  ...
}: let
  userName = "rikki";
in {
  # 笔记本上的用户特定配置（非硬件相关）
  home-manager.users.${userName} = {
    # 笔记本上常用的便携工具
    home.packages = with pkgs; [
      powertop
      acpi
      brightnessctl
    ];

    # 笔记本特定的 shell 别名（用户层面）
    programs.fish.shellAliases = {
      "power-usage" = "sudo powertop";
      "brightness" = "brightnessctl";
      "battery" = "acpi -b";
    };

    # 笔记本环境下的 Git 配置（比如使用不同的邮箱）
    programs.git = {
      userEmail = lib.mkForce "rikki@member.fsf.org"; # 示例：笔记本特定邮箱
      extraConfig = {
        # 笔记本上可能使用不同的代理设置等
      };
    };
  };
}
