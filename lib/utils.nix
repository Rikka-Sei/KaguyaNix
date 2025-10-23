{lib}: {
  # 为指定的用户和系统生成配置模块列表
  generateUserModules = systemName: users:
    lib.flatten (
      lib.mapAttrsToList (
        username: userCfg: let
          userDir = ../users + "/${username}";

          # 基础配置 - 使用路径而不是字符串
          baseConfigPath = userDir + "/base.nix";
          baseConfig =
            if builtins.pathExists baseConfigPath
            then [baseConfigPath]
            else [];

          # profile 配置
          profileConfigs = map (profile: userDir + "/profiles/${profile}.nix") userCfg.profiles;

          # 系统特定配置
          systemConfigPath = userDir + "/per-system/${systemName}.nix";
          systemConfig =
            if builtins.pathExists systemConfigPath
            then [systemConfigPath]
            else [];
        in
          baseConfig ++ profileConfigs ++ systemConfig
      )
      users
    );

  # 生成系统模块列表
  generateSystemModules = systemConfig: let
    # 硬件配置 - 使用路径而不是字符串
    hardwareModule = ../hardware + "/${systemConfig.hardware}/configuration.nix";

    # 额外模块路径解析
    moduleResolver = module:
      if builtins.pathExists (../modules + "/${module}.nix")
      then ../modules + "/${module}.nix"
      else ../modules + "/${module}";

    extraModules = map moduleResolver (systemConfig.modules or []);
  in
    [hardwareModule] ++ extraModules;
}
