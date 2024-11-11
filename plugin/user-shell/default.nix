{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.user-shell;

  userOpts = {name, ...}: {
    options = {
      enable = mkOption {
        type = with types; bool;
        default = false;
      };

      defaultShell = mkOption {
        type = types.str;
        default = "bash";
      };

      bash = {
        bashrcExtra = mkOption {
          type = types.lines;
          default = "";
        };

        blesh = {
          enable = mkOption {
            type = with types; bool;
            default = false;
          };
        };

        starship = {
          enable = mkOption {
            type = with types; bool;
            default = false;
          };
        };
      };

      gnupg = {
        enable = mkOption {
          type = with types; bool;
          default = false;
        };
      };
    };
  };
in {
  imports = [
    ./envs
  ];
  options = {
    user-shell = mkOption {
      type = with types; attrsOf (submodule userOpts);
    };
  };
}
