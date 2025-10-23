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

  # 检查架构是否为 darwin
  isDarwin = architecture: lib.hasSuffix "-darwin" architecture;

  # 构建系统配置
  mkSystem = systemFile: let
    # 从文件名提取系统名称 (去掉 .nix 后缀)
    systemName = lib.removeSuffix ".nix" systemFile;

    # 读取系统配置来获取架构信息
    systemConfig = import ../systems/${systemFile};
    
    # 获取架构信息
    architecture = systemConfig.systemConfig.architecture or "x86_64-linux";
    
    # 合并 inputs (基础 inputs + 系统特定的 inputsOverride)
    mergedInputs = inputs // (systemConfig.systemConfig.inputsOverride or {});

    # 生成用户配置模块
    userModules =
      utils.generateUserModules
      systemName
      (systemConfig.systemConfig.users or {});

    # 生成系统模块
    systemModules =
      utils.generateSystemModules
      (systemConfig.systemConfig or {});

    # 根据架构选择构建函数和模块
    buildSystemConfig = 
      if isDarwin architecture
      then {
        # Darwin 系统配置
        builder = mergedInputs.nix-darwin.lib.darwinSystem;
        nixpkgsInput = mergedInputs.nixpkgs-darwin or mergedInputs.nixpkgs;
        nixpkgsUnstableInput = mergedInputs.nixpkgs-unstable or mergedInputs.nixpkgs;
        platformModules = [
          # Darwin 特定模块
        ] ++ (if mergedInputs ? home-manager && mergedInputs.home-manager ? darwinModules 
              then [ mergedInputs.home-manager.darwinModules.home-manager ]
              else []);
      }
      else {
        # NixOS 系统配置
        builder = mergedInputs.nixpkgs.lib.nixosSystem;
        nixpkgsInput = mergedInputs.nixpkgs;
        nixpkgsUnstableInput = mergedInputs.nixpkgs-unstable or mergedInputs.nixpkgs;
        platformModules = [
          # NixOS 特定模块
        ] ++ (if mergedInputs ? nix-flatpak 
              then [ mergedInputs.nix-flatpak.nixosModules.nix-flatpak ]
              else [])
          ++ (if mergedInputs ? home-manager && mergedInputs.home-manager ? nixosModules
              then [ mergedInputs.home-manager.nixosModules.home-manager ]
              else []);
      };
  in
    (if isDarwin architecture
     then 
       # Darwin 系统使用 nix-darwin.lib.darwinSystem，并添加 system 属性
       (buildSystemConfig.builder {
         modules =
           [
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
           ++ userModules; # 添加动态生成的模块
         
         specialArgs = {
           inputs = mergedInputs;  # 使用合并后的 inputs
           unstable = import buildSystemConfig.nixpkgsUnstableInput {
             system = architecture;
             config.allowUnfree = true;
           };
         };
       }) // { 
         # 为 Darwin 配置添加 system 属性，这样 darwin-rebuild 就能找到它
         system = architecture; 
       }
     else
       # NixOS 系统使用 nixpkgs.lib.nixosSystem
       buildSystemConfig.builder {
         specialArgs = {
           inputs = mergedInputs;  # 使用合并后的 inputs
           unstable = import buildSystemConfig.nixpkgsUnstableInput {
             system = architecture;
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
               nixpkgs.hostPlatform = architecture;
             }

             # 系统特定配置
             ../systems/${systemFile}
           ]
           ++ buildSystemConfig.platformModules
           ++ systemModules
           ++ userModules; # 添加动态生成的模块
       }
    );
  # 基于 architecture 的系统分流器
  getArchitecture = name: 
    let 
      rawConfig = import ../systems/${name};
      # 提供系统配置函数需要的基本参数
      systemConfig = if lib.isFunction rawConfig 
                     then rawConfig { 
                       pkgs = null; 
                       lib = lib; 
                       config = {}; 
                       options = {}; 
                     }
                     else rawConfig;
    in systemConfig.systemConfig.architecture or "x86_64-linux";

  # 分离 Darwin 和 NixOS 系统
  darwinSystems = lib.filterAttrs (name: _: 
    isDarwin (getArchitecture name)
  ) systemNames;

  nixosSystems = lib.filterAttrs (name: _: 
    !(isDarwin (getArchitecture name))
  ) systemNames;

in {
  flake = {
    # NixOS 系统配置
    nixosConfigurations =
      lib.mapAttrs' (
        name: _:
          lib.nameValuePair (lib.removeSuffix ".nix" name) (mkSystem name)
      )
      nixosSystems;

    # Darwin 系统配置 - 直接使用 nix-darwin.lib.darwinSystem
    darwinConfigurations =
      lib.mapAttrs' (
        name: _:
          let
            systemName = lib.removeSuffix ".nix" name;
            rawSystemConfig = import ../systems/${name};
            
            # 获取实际的系统配置
            systemConfig = if lib.isFunction rawSystemConfig 
                          then rawSystemConfig { 
                            pkgs = null; 
                            lib = lib; 
                            config = {}; 
                            options = {}; 
                          }
                          else rawSystemConfig;
            
            # 获取架构信息
            architecture = systemConfig.systemConfig.architecture or "x86_64-darwin";
            
            # 合并 inputs
            mergedInputs = inputs // (systemConfig.systemConfig.inputsOverride or {});
            
            # 生成用户和系统模块
            userModules = utils.generateUserModules systemName (systemConfig.systemConfig.users or {});
            systemModules = utils.generateSystemModules (systemConfig.systemConfig or {});
          in
          lib.nameValuePair systemName (
            mergedInputs.nix-darwin.lib.darwinSystem {
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
                ../systems/${name}
              ] ++ (if mergedInputs ? home-manager && mergedInputs.home-manager ? darwinModules 
                    then [ mergedInputs.home-manager.darwinModules.home-manager ]
                    else [])
                ++ systemModules
                ++ userModules;
              
              specialArgs = {
                inputs = mergedInputs;
                unstable = import (mergedInputs.nixpkgs-unstable or mergedInputs.nixpkgs) {
                  system = architecture;
                  config.allowUnfree = true;
                };
              };
            }
          )
      )
      darwinSystems;
  };
}
