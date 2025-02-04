{ lib, ... }:
let
  inherit (lib) mkOption types;

  inherit (types)
    lines
    bool
    str
    enum
    attrsOf
    listOf
    submodule
    ;

  bash = {
    bashrcExtra = mkOption {
      type = lines;
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
        type = bool;
        default = false;
        example = false;
        description = ''
          Choose whether to enable the blesh feature.
        '';
      };
    };

    starship = {
      enable = mkOption {
        type = bool;
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
          type = bool;
          default = false;
          example = false;
          description = ''
            Choose whether to enable the users-shell feature for a specific user.
          '';
        };

        defaultShell = mkOption {
          type = str;
          default = "bash";
          example = "fish";
          description = ''
            Select the default shell environment for a specific user.
          '';
        };

        defaultShellOptions = {

        };

        languageServer = mkOption {
          type = listOf (enum [
            "nil"
            "alejandra"
          ]);
          default = [ ];
          example = [ "nil" ];
          description = ''
            Select supported languageServer for a specific user.
          '';
        };
      };
    };
in
{
  imports = [
    ./users
    ./variables
  ];

  options = {
    user-envirentment = {
      users = mkOption {
        type = attrsOf (submodule userOpts);
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

      variables = {
        tracker-raw = mkOption {
          type = listOf str;
          default = "";
          example = [
            "udp://a:1337/announce"
            "udp://b:1337/announce"
          ];
          description = ''
            A string of tracker URLs separated by commas.
          '';
        };

        tracker-aria2 = mkOption {
          type = str;
          default = "";
          example = "udp://a:1337/announce,udp://b:1337/announce,...";
          description = ''
            A string of tracker URLs separated by commas.
          '';
        };
      };
    };
  };
}
