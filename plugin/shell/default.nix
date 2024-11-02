{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.user-shell;

  trackerList = import ./aria2-tracker;

  userOpts = {name, ...}: {
    options = {
      defaultShell = mkOption {
        type = types.str;
        default = "bash";
      };
    };
  };
in {
  imports = [
    ./fish
  ];
  options = {
    user-shell = mkOption {
      type = with types; attrsOf (submodule userOpts);
      default = {};
    };
  };
}
