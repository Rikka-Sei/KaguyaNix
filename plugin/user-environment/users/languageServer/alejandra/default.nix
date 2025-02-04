{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs mkIf;
  inherit (lib.lists) elem;

  system = pkgs.stdenv.hostPlatform.system;
  root = config.user-environment;
  cfg = root.users;

  plugin-conf =
    name: value:
    let
      # inner cfg, helps function to locate specific configs
      icfg = value.languageServer;
    in
    mkIf (elem "alejandra" icfg) { home.packages = [ inputs.alejandra.defaultPackage.${system} ]; };

  # Check whether the `user-environment` module is enabled for this user.
  isEnabled = v: v.enable;
in
{
  config = {
    home-manager.users = mapAttrs (
      userName: userConfig: mkIf (isEnabled userConfig) (plugin-conf userName userConfig)
    ) cfg;
  };
}
