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

  gnupg = {
    enable = mkOption {
      type = with types; bool;
      default = false;
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
  imports = [ ./envs ];
  options = {
    user-shell = mkOption {
      type = with types; attrsOf (submodule userOpts);
      example = {
        rikki = {
          enable = true;
          defaultShell = "fish";
        };
      };
      description = ''
        simplify user's shell config  
      '';
    };
  };
}
