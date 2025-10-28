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
      "cross-platform/linux-builder"
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

  # Linux Builder 配置
  # 根据 MacBook Pro 2019 硬件规格优化:
  # - 4 物理核心 / 8 逻辑核心
  # - 8 GB 内存
  # - 348 GB 可用磁盘空间
  services.linux-builder = {
    cores = 3; # 分配 3 个核心给 VM (保留 1 个物理核心给 macOS)
    memorySize = 3072; # 分配 3GB 内存给 VM (保留 5GB 给 macOS)
    diskSize = 25000; # 分配 25GB 磁盘空间给 VM
    maxJobs = 3; # 最大并行任务数设置为核心数
    ephemeral = true; # 临时模式: VM 关闭后状态丢失，节省磁盘空间
  };

  # 用于向后兼容性
  system.stateVersion = 6;
}
