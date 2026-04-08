# MacBook Pro M2 硬件配置
{
  config,
  lib,
  pkgs,
  ...
}: {
  # 设置主用户 - 新版本 nix-darwin 需要为 system.defaults 设置主用户
  system.primaryUser = "rikki";

  system.defaults = {
    NSGlobalDomain."com.apple.swipescrolldirection" = false;

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    # Dock 配置
    dock = {
      autohide = true;
      orientation = "bottom";
    };

    # Finder 配置
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
    };
  };

  # 安全配置 - 在 nix-darwin 中启用 Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
}
