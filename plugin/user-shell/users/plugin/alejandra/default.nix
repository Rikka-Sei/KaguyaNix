{
  alejandra,
  lib,
  config,
  pkgs,
  system ? pkgs.stdenv.hostPlatform.system,
  ...
}:
let
  inherit (lib) mapAttrs mkIf;
  inherit (lib.lists) elem;

  root = config.user-shell;
  cfg = root.users;

  plugin-conf =
    name: value:
    let
      # inner cfg, helps function to locate specific configs
      icfg = value.languageServer;
    in
    mkIf (elem "alejandra" icfg) { 
      home.packages = [ alejandra.defaultPackage.${system} ]; 
    };

  # Check whether the `user-shell` module is enabled for this user.
  isEnabled = v: v.enable;

  userConfigs = mapAttrs 
    (userName: userConfig: 
      mkIf (isEnabled userConfig) {
        home-manager.users.${userName} = plugin-conf userName userConfig;
    }) 
    cfg;
in
{
  home-manager = {
      users = lib.mkMerge (lib.attrValues userConfigs);
  };
}
