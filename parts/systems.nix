{
  self,
  inputs,
  lib,
  ...
}: let
  # 导入通用工具函数
  utils = import ../lib/utils.nix {inherit lib;};

  # 扫描 systems 目录获取所有系统配置
  systemFiles = builtins.readDir ../systems;

  # 过滤出 .nix 文件
  systemNames =
    lib.filterAttrs (
      name: type:
        type == "regular" && lib.hasSuffix ".nix" name
    )
    systemFiles;

  # 构建 nixosConfigurations
  mkSystem = systemFile: let
    # 从文件名提取系统名称 (去掉 .nix 后缀)
    systemName = lib.removeSuffix ".nix" systemFile;

    # 读取系统配置来获取架构信息
    systemConfig = import ../systems/${systemFile};

    # 生成用户配置模块
    userModules =
      utils.generateUserModules
      systemName
      (systemConfig.systemConfig.users or {});

    # 生成系统模块
    systemModules =
      utils.generateSystemModules
      (systemConfig.systemConfig or {});
  in
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        unstable = import inputs.nixpkgs-unstable {
          system = systemConfig.systemConfig.architecture or "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      modules =
        [
          # 核心框架
          ../lib/system-framework.nix
          ../lib/user-framework.nix

          # 通用配置
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.hostPlatform = systemConfig.systemConfig.architecture or "x86_64-linux";
          }

          # 系统特定配置
          ../systems/${systemFile}

          # 其他 inputs 的模块
          inputs.nix-flatpak.nixosModules.nix-flatpak
          inputs.home-manager.nixosModules.home-manager
        ]
        ++ systemModules
        ++ userModules; # 添加动态生成的模块
    };
in {
  flake = {
    nixosConfigurations =
      lib.mapAttrs' (
        name: _:
          lib.nameValuePair (lib.removeSuffix ".nix" name) (mkSystem name)
      )
      systemNames;
  };
}
