{ pkgs, ... }:
{
  networking.hostName = "Rikkis-MacBook-Pro";

  systemConfig = {
    architecture = "x86_64-darwin";
    hardware = "mbp2019";

    users = {
      rikki.profiles = [
        "development"
        "software"
        "business"
        "lifetime"
      ];
    };

    modules = [
      "development/base"
      "development/emacs"
    ];

    # 演示 inputs 覆盖功能 - 可以为特定系统定制 inputs
    inputsOverride = {
      # 这里可以覆盖或添加特定的 inputs
      # 例如：使用特定版本的 nixpkgs
      # nixpkgs.url = "github:NixOS/nixpkgs/specific-commit";
    };
  };

  # Darwin 系统级配置
  time.timeZone = "Asia/Shanghai";

  # 启用实验性功能
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "@admin"
      "rikki"
    ];
  };

  # 用于向后兼容性
  system.stateVersion = 6;
}
