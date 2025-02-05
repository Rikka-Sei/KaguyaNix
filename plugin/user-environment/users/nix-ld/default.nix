{ lib, config, ... }:
let
  inherit (lib)
    mapAttrs
    mkIf
    attrValues
    any
    concatLists
    ;

  root = config.user-environment;
  cfg = root.users;

  # Check whether the `user-environment` module is enabled for this user.
  isEnabled = v: v.enable;

  for =
    subpath:
    attrValues (mapAttrs (_: userConfig: mkIf (isEnabled userConfig) (userConfig.${subpath})) cfg);

  isNixLdEnable = any (key: key) (for "nix-ld.enable");

  packages = concatLists (for "nix-ld.packages");

in
{
  config = {
    programs.nix-ld.dev = {
      enable = isNixLdEnable;
      libraries = packages;
    };
  };
}
