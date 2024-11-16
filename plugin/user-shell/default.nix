{ config, lib, ... }:
with lib;
let
  cfg = config.user-shell;

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

  userOpts =
    { name, ... }:
    {
      options = {
        enable = mkOption {
          type = with types; bool;
          default = false;
        };

        defaultShell = mkOption {
          type = types.str;
          default = "bash";
        };

        # load shell options
        inherit bash;

        # load plugin options
        inherit gnupg;
      };
    };
in
{
  imports = [
    ./envs
    ./variables
  ];

  options = {
    user-shell = {
      users = mkOption {
        type = with types; attrsOf (submodule userOpts);
        example = {
          rikki = {
            enable = true;
            defaultShell = "fish";
          };
        };
        description = ''
          Simplify the user's shell configuration.
        '';
      };
    };

    variables = {
      tracker-aria2 = mkOption {
        type = with types; str;
        example = "udp://a:1337/announce,udp://b:1337/announce,...";
        description = ''
          A string of tracker URLs separated by commas.
        '';
      };
    };
  };
}
