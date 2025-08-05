{
  self,
  inputs,
  lib,
  ...
}: let
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
  in
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        unstable = import inputs.nixpkgs-unstable {
          system = systemConfig.systemConfig.architecture or "x86_64-linux";
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
        }

        # 系统特定配置
        ../systems/${systemFile}

        # 其他 inputs 的模块
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.home-manager.nixosModules.home-manager
      ];
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
