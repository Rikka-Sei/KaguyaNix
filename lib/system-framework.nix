{
  lib,
  config,
  ...
}: {
  options.systemConfig = lib.mkOption {
    type = lib.types.submodule {
      options = {
        architecture = lib.mkOption {
          type = lib.types.str;
          description = "系统架构";
        };

        hardware = lib.mkOption {
          type = lib.types.str;
          description = "硬件配置名称";
        };

        modules = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "额外模块列表";
        };
      };
    };
    description = "系统配置";
  };

  config = {
    nixpkgs.hostPlatform = config.systemConfig.architecture;

    imports =
      [
        # 硬件配置
        ../hardware/${config.systemConfig.hardware}/configuration.nix
      ]
      ++
      # 额外模块
      (map (module: ../modules/${module}) config.systemConfig.modules);
  };
}
