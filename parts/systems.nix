{
  self,
  inputs,
  lib,
  ...
}:
let
  # 扩展 lib，自动加载 lib/ 目录下的所有函数
  extendedLib = lib.extend (
    final: prev: let
      # 扫描 lib 目录获取所有 .nix 文件
      libFiles = builtins.readDir ../lib;

      # 过滤出 .nix 文件并构建属性集
      libExtensions = builtins.listToAttrs (
        map (name: let
          # 去掉 .nix 后缀作为属性名
          attrName = lib.removeSuffix ".nix" name;
          # 导入对应文件
          attrValue = import (../lib + "/${name}") { lib = final; };
        in {
          name = attrName;
          value = attrValue;
        }) (
          builtins.filter (name:
            libFiles.${name} == "regular" &&
            lib.hasSuffix ".nix" name
          ) (builtins.attrNames libFiles)
        )
      );
    in libExtensions
  );

  # 导入框架构建工具（从 parts/ 目录）
  utils = import ./utils.nix { lib = extendedLib; };

  # 加载所有 packages
  packages = extendedLib.packages.loadPackages ../packages;

  # 扫描 systems 目录获取所有系统配置
  systemFiles = builtins.readDir ../systems;

  # 过滤出 .nix 文件
  systemNames = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".nix" name
  ) systemFiles;

  # 构建系统配置
  mkSystem =
    systemFile:
    let
      # 从文件名提取系统名称 (去掉 .nix 后缀)
      systemName = lib.removeSuffix ".nix" systemFile;

      # 读取系统配置来获取架构信息
      rawConfig = import ../systems/${systemFile};
      # 如果是函数，调用它获取配置；否则直接使用
      systemConfig =
        if lib.isFunction rawConfig then
          rawConfig {
            pkgs = null;
            lib = lib;
            config = { };
          }
        else
          rawConfig;

      # 获取架构信息
      architecture = systemConfig.systemConfig.architecture or "x86_64-linux";

      # 从架构和 inputs 推断版本
      # 最简单的方法：检查 inputs 中是否有 nixpkgs-darwin，以及它指向哪个分支
      # 由于 nixpkgs-25.05-darwin 内部版本号错误标记为 25.11，我们直接用 "25.05"
      nixpkgsVersion = "25.05";

      # 加载版本特定的补丁
      patches = import ./patch/default.nix {
        lib = extendedLib;
        inherit architecture nixpkgsVersion;
      };

      # 合并 inputs (基础 inputs + 系统特定的 inputsOverride)
      mergedInputs = inputs // (systemConfig.systemConfig.inputsOverride or { });

      # 生成用户配置模块
      userModules = utils.generateUserModules systemName (systemConfig.systemConfig.users or { });

      # 生成系统模块
      systemModules = utils.generateSystemModules (systemConfig.systemConfig or { });

      # 根据架构选择平台配置 (类似 switch/case)
      buildSystemConfig =
        if extendedLib.arch.isDarwin architecture then
          {
            builder = mergedInputs.nix-darwin.lib.darwinSystem;
            nixpkgsInput = mergedInputs.nixpkgs-darwin;
            nixpkgsUnstableInput = mergedInputs.nixpkgs-unstable or mergedInputs.nixpkgs-darwin;
            platformModules = [
              # Darwin 特定模块
            ]
            ++ (
              if mergedInputs ? home-manager && mergedInputs.home-manager ? darwinModules then
                [ mergedInputs.home-manager.darwinModules.home-manager ]
              else
                [ ]
            );
          }
        else if extendedLib.arch.isLinux architecture then
          {
            builder = mergedInputs.nixpkgs.lib.nixosSystem;
            nixpkgsInput = mergedInputs.nixpkgs;
            nixpkgsUnstableInput = mergedInputs.nixpkgs-unstable or mergedInputs.nixpkgs;
            platformModules = [
              # NixOS 特定模块
            ]
            ++ (
              if mergedInputs ? nix-flatpak then [ mergedInputs.nix-flatpak.nixosModules.nix-flatpak ] else [ ]
            )
            ++ (
              if mergedInputs ? home-manager && mergedInputs.home-manager ? nixosModules then
                [ mergedInputs.home-manager.nixosModules.home-manager ]
              else
                [ ]
            );
          }
        else
          throw "Unsupported architecture: ${architecture}";
      # 通用的系统构建参数
      systemBuildArgs = {
        specialArgs = {
          inputs = mergedInputs;
          systemName = systemName;  # 传递系统名称给模块
          lib = extendedLib;        # 传递扩展的 lib（包含 per-sys、arch、packages 等）
          unstable = import buildSystemConfig.nixpkgsUnstableInput {
            system = architecture;
            config.allowUnfree = true;
          };
        };

        modules = [
          # 核心框架
          ./options/system.nix
          ./options/user.nix

          # Packages overlay 和模块
          {
            nixpkgs.overlays = [ packages.overlay ];
          }
          packages.module

          # 通用配置
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.hostPlatform = architecture;
          }

          # 系统特定配置
          ../systems/${systemFile}
        ]
        ++ buildSystemConfig.platformModules
        ++ systemModules
        ++ userModules
        ++ patches.getModules;  # 添加版本特定的补丁模块
      }
      // patches.getBuildArgs;  # 合并版本特定的构建参数

      # 构建系统配置
      builtSystem = buildSystemConfig.builder systemBuildArgs;
    in
    builtSystem;

  # 系统过滤器 - 根据条件筛选系统
  systemFilter =
    predicate:
    lib.filterAttrs (
      name: _:
      let
        rawConfig = import ../systems/${name};
        # 如果是函数，调用它获取配置；否则直接使用
        systemConfig =
          if lib.isFunction rawConfig then
            rawConfig {
              pkgs = null;
              lib = lib;
              config = { };
            }
          else
            rawConfig;
        architecture = systemConfig.systemConfig.architecture or "x86_64-linux";
      in
      predicate architecture
    ) systemNames;

  # 分离 Darwin 和 NixOS 系统
  darwinSystems = systemFilter extendedLib.arch.isDarwin;
  nixosSystems = systemFilter extendedLib.arch.isLinux;

in
{
  flake = {
    # NixOS 系统配置
    nixosConfigurations = lib.mapAttrs' (
      name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (mkSystem name)
    ) nixosSystems;

    # Darwin 系统配置 - 复用 mkSystem
    darwinConfigurations = lib.mapAttrs' (
      name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (mkSystem name)
    ) darwinSystems;
  };
}
