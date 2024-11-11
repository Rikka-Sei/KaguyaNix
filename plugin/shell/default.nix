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

      bashConf = {
        bashrcExtra = mkOption {
          type = types.lines;
          default = "";
        };

        blesh = {
          enable = mkOption {
            type = with types; bool;
            default = true;
          };
        };

        starship = {
          enable = mkOption {
            type = with types; bool;
            default = true;
          };
        };
      };
    };
  };
in {
  imports = [
    ./fish
    ./bash
  ];
  options = {
    user-shell = mkOption {
      type = with types; attrsOf (submodule userOpts);
    };
  };
}
