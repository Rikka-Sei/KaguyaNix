{
  pkgs,
  config,
  lib,
  home-manager,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    mkIf
    literalExpression
    mkMerge
    ;

  cfg = config.user-shell;

  trackerList = import ./aria2-tracker;

  usModule = types.submoduleWith {
    description = "User Shell Module";
    class = "userShell";
    specialArgs =
      {
        inherit trackerList;
        # set an alias for "config"
        # prevent system "config" to overide submodule's inner "config" data
        osConfig = config;
      }
      // cfg.extraSpecialArgs;
    modules = [
      ({...}: {
        imports =
          import ./fish {
          };
        # [
        #   ./fish
        #   ./bash
        # ];

        # export option "defaultShell" to imported modules
        options.defaultShell = mkOption {
          type = types.str;
          default = "fish";
          example = "bash";
          description = ''
            Set default shell for users.
            available: bash,fish
          '';
        };
      })
    ];
  };
in {
  options.user-shell = {
    extraSpecialArgs = mkOption {
      type = types.attrs;
      default = {};
      example = literalExpression "{ inherit userName; }";
      description = ''
        Extra `specialArgs` passed to User Shell. This
        option can be used to pass additional arguments to all modules.
      '';
    };

    users = mkOption {
      type = types.attrsOf usModule;
      default = {};
      # Prevent the entire submodule being included in the documentation.
      visible = "shallow";
      description = ''
        Per-user User Shell configuration.
      '';
    };
  };
}
