{ config, lib, ... }:
with lib;
let
  cfg = config.user-shell;

  bash = {
    bashrcExtra = mkOption {
      type = types.lines;
      default = "";
      example = ''
        export username=rikki
      '';
      description = ''
        Extra commands that should be placed in {file}~/.bashrc.
        Note that these commands will be run even in non-interactive shells.
        (Inherit from parent)
      '';
    };

    blesh = {
      enable = mkOption {
        type = with types; bool;
        default = false;
        example = false;
        description = ''
          Choose whether to enable the blesh feature.
        '';
      };
    };

    starship = {
      enable = mkOption {
        type = with types; bool;
        default = false;
        example = false;
        description = ''
          Choose whether to enable the starship feature.
        '';
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
          example = false;
          description = ''
            Choose whether to enable the users-shell feature for a specific user.
          '';
        };

        defaultShell = mkOption {
          type = types.str;
          default = "bash";
          example = "fish";
          description = ''
            Select the default shell environment for a specific user.
          '';
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
        default = "";
        example = "udp://a:1337/announce,udp://b:1337/announce,...";
        description = ''
          A string of tracker URLs separated by commas.
        '';
      };
    };
  };
}
