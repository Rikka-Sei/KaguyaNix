{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs mkIf elem;
  
  system = pkgs.stdenv.hostPlatform.system;
  root = config.user-shell;
  cfg = root.users;
  
  plugin-conf =
    name: value:
    let
      # inner cfg, helps function to locate specific configs
      icfg = value.languageServer;
    in
    mkIf (elem "nil" icfg) { 
      home.packages = [ inputs.nil.packages.${system}.default ]; 
    };

  # Check whether the `user-shell` module is enabled for this user.
  isEnabled = v: v.enable;

  userConfigs = mapAttrs 
    (userName: userConfig: 
      mkIf (isEnabled userConfig) {
        ${userName} = plugin-conf userName userConfig;
    }) 
    cfg;
in
{
  config = {
    home-manager.users = lib.mkMerge (lib.attrValues userConfigs);
  };
}
