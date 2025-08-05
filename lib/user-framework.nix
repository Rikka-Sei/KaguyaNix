{
  lib,
  config,
  ...
}: {
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

  config = {
    imports = lib.flatten (
      lib.mapAttrsToList (
        username: userCfg: let
          userDir = ../users/${username};
          systemName = config.networking.hostName;

          # 基础配置
          baseConfig =
            if builtins.pathExists "${userDir}/base.nix"
            then ["${userDir}/base.nix"]
            else [];

          # profile 配置
          profileConfigs = map (profile: "${userDir}/profiles/${profile}.nix") userCfg.profiles;

          # 系统特定配置
          systemConfig =
            if builtins.pathExists "${userDir}/per-system/${systemName}.nix"
            then ["${userDir}/per-system/${systemName}.nix"]
            else [];
        in
          baseConfig ++ profileConfigs ++ systemConfig
      )
      config.systemConfig.users
    );
  };
}
