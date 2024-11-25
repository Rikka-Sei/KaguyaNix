{
  nil,
  lib,
  config,
  pkgs,
  system ? pkgs.stdenv.hostPlatform.system,
  ...
}:
let
  inherit (lib) mapAttrs mkIf elem;

  root = config.user-shell;
  cfg = root.users;

  plugin-conf =
    name: value:
    let
      # inner cfg, helps function to locate specific configs
      icfg = value.languageServer;
    in
    mkIf (elem "nil" icfg) { home.packages = [ nil.packages.${system}.default ]; };

  # Check whether the `user-shell` module is enabled for this user.
  isEnabled = v: v.enable;
in
{
  config = {
    home-manager.users = mapAttrs (name: v: mkIf (isEnabled v) (plugin-conf name v)) cfg;
  };
}
