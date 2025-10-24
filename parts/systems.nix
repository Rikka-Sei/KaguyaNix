{
  self,
  inputs,
  lib,
  ...
}:
let
  # 导入通用工具函数
  utils = import ../lib/utils.nix { inherit lib; };
  arch = import ../lib/arch.nix { inherit lib; };

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
      systemConfig = import ../systems/${systemFile};

      # 获取架构信息
      architecture = systemConfig.systemConfig.architecture or "x86_64-linux";

      # 合并 inputs (基础 inputs + 系统特定的 inputsOverride)
      mergedInputs = inputs // (systemConfig.systemConfig.inputsOverride or { });

      # 生成用户配置模块
      userModules = utils.generateUserModules systemName (systemConfig.systemConfig.users or { });

      # 生成系统模块
      systemModules = utils.generateSystemModules (systemConfig.systemConfig or { });

      # 根据架构选择平台配置 (类似 switch/case)
      buildSystemConfig =
        if arch.isDarwin architecture then
          {
            builder = mergedInputs.nix-darwin.lib.darwinSystem;
            nixpkgsInput = mergedInputs.nixpkgs-darwin or mergedInputs.nixpkgs;
            nixpkgsUnstableInput = mergedInputs.nixpkgs-unstable or mergedInputs.nixpkgs;
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
        else if arch.isLinux architecture then
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
          unstable = import buildSystemConfig.nixpkgsUnstableInput {
            system = architecture;
            config.allowUnfree = true;
          };
        };

        modules = [
          # 核心框架
          ../lib/system-framework.nix
          ../lib/user-framework.nix

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
        ++ userModules;
      };

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
        systemConfig = if lib.isFunction rawConfig
                       then rawConfig { pkgs = null; lib = lib; config = {}; }
                       else rawConfig;
        architecture = systemConfig.systemConfig.architecture or "x86_64-linux";
      in
      predicate architecture
    ) systemNames;

  # 分离 Darwin 和 NixOS 系统
  darwinSystems = systemFilter arch.isDarwin;
  nixosSystems = systemFilter arch.isLinux;

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
