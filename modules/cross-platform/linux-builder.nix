# Linux Builder Module for macOS
#
# 提供在 macOS 上构建 Linux 包的能力，通过在后台运行一个轻量级的 NixOS QEMU VM。
# 这对于需要构建 Linux 包但又在 macOS 上开发的场景非常有用。
#
# 使用示例:
#   systemConfig.modules = [ "cross-platform/linux-builder" ];
#
#   services.linux-builder = {
#     enable = true;
#     cores = 8;
#     memorySize = 8192;  # 8GB
#     diskSize = 30000;   # 30GB
#   };

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.linux-builder;
in
{
  options.services.linux-builder = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        启用 Linux Builder VM。
        加载此模块即默认启用，符合 KaguyaNix "约定优于配置" 的设计理念。
        如需禁用，请显式设置为 false。
      '';
    };

    cores = mkOption {
      type = types.int;
      default = 4;
      description = ''
        CPU 核心数分配给 Linux Builder VM。
        建议设置为物理核心数的 50-75%。
      '';
    };

    memorySize = mkOption {
      type = types.int;
      default = 4096;
      description = ''
        内存大小（MB）分配给 Linux Builder VM。
        最小推荐 2048 MB，对于大型构建建议 8192 MB 或更多。
      '';
    };

    diskSize = mkOption {
      type = types.int;
      default = 20000;
      description = ''
        磁盘大小（MB）分配给 Linux Builder VM。
        用于存储 Nix store 和构建临时文件。
        最小推荐 20000 MB (20GB)。
      '';
    };

    maxJobs = mkOption {
      type = types.int;
      default = 4;
      description = ''
        最大并行构建任务数。
        通常设置为 CPU 核心数。
      '';
    };

    speedFactor = mkOption {
      type = types.int;
      default = 1;
      description = ''
        构建速度因子，用于 Nix 调度器。
        较高的值表示该构建器速度更快，会优先使用。
      '';
    };

    supportedFeatures = mkOption {
      type = types.listOf types.str;
      default = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      description = ''
        该构建器支持的特性列表。
        常见特性: nixos-test, benchmark, big-parallel, kvm
      '';
    };

    ephemeral = mkOption {
      type = types.bool;
      default = true;
      description = ''
        是否使用临时模式运行 VM。
        临时模式下，VM 关闭后所有状态都会丢失。
      '';
    };
  };

  config = mkIf cfg.enable {
    # 仅在 Darwin 系统上启用
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "Linux Builder 仅支持在 macOS (Darwin) 系统上运行";
      }
    ];

    # 配置 nix-darwin 的 Linux Builder
    nix.linux-builder = {
      enable = true;
      ephemeral = cfg.ephemeral;
      maxJobs = cfg.maxJobs;

      config = {
        virtualisation = {
          cores = mkDefault cfg.cores;
          memorySize = mkDefault cfg.memorySize;
          diskSize = mkDefault cfg.diskSize;
        };
      };
    };

    # 配置 Nix 以信任 Linux Builder
    nix.settings = {
      # 信任的用户列表（必需）
      # 注意：如果系统配置中已经设置了 trusted-users，这里会追加
      trusted-users = [ "@admin" ];

      # 使用替代品加速构建
      builders-use-substitutes = mkDefault true;
    };

    # 添加有用的提示信息到系统环境
    environment.etc."linux-builder-info.txt".text = ''
      Linux Builder 配置信息
      =====================

      状态: 已启用
      CPU 核心数: ${toString cfg.cores}
      内存: ${toString cfg.memorySize} MB
      磁盘: ${toString cfg.diskSize} MB
      最大并行任务: ${toString cfg.maxJobs}
      临时模式: ${if cfg.ephemeral then "是" else "否"}

      验证 Linux Builder:
        nix build --expr '(import <nixpkgs> { system = "x86_64-linux"; }).hello' --impure

      查看构建器状态:
        nix show-config | grep builders

      管理 VM:
        # 启动 VM
        sudo launchctl kickstart -k system/org.nixos.linux-builder

        # 停止 VM
        sudo launchctl stop system/org.nixos.linux-builder

        # 查看 VM 状态
        sudo launchctl list | grep linux-builder
    '';
  };
}
