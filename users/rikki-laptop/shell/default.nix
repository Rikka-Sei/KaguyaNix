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
        default = "fish";
      };
    };
    config = {
      programs.fish.enable = true;
    };
  };
in {
  # imports = [
  #   ./fish
  # ];

  options = {
    user-shell = mkOption {
      type = with types; attrsOf (submodule userOpts);
      default = {};
    };

    test = mkOption {
      type = types.number;
      default = 0;
    };
  };
}
