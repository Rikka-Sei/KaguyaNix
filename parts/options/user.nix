{lib, ...}: {
  options.systemConfig.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        profiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "用户配置档案列表";
        };
      };
    });
    default = {};
    description = "系统用户配置";
  };
}
