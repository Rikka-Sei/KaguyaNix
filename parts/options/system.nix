{lib, ...}: {
  options.systemConfig = lib.mkOption {
    type = lib.types.submodule {
      options = {
        architecture = lib.mkOption {
          type = lib.types.str;
          description = "系统架构 (如 x86_64-linux, x86_64-darwin, aarch64-darwin)";
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

        inputsOverride = lib.mkOption {
          type = lib.types.attrs;
          default = {};
          description = "覆盖或添加特定的 flake inputs";
        };
      };
    };
    description = "系统配置";
  };
}
