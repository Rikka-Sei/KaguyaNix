{
  pkgs,
  config,
  lib,
  home-manager,
  ...
}:
with lib; let
  cfg = config.user-shell;

  trackerList = import ./aria2-tracker;

  usModule = types.submoduleWith {
    description = "User Shell Module";
    class = "userShell";
    specialArgs =
      {
        inherit trackerList;
        inherit lib;
        inherit home-manager;
        # inherit programs;
        # set an alias for "config"
        # prevent system "config" to overide submodule's inner "config" data
        osConfig = config;
      }
      // cfg.extraSpecialArgs;
    modules = [
      {
        # export option "defaultShell" to imported modules
        options.defaultShell = mkOption {
          type = types.str;
          default = "bash";
          example = literalExpression "bash";
          description = ''
            Set default shell for users.
            available: bash,fish
          '';
        };
      }
      ({name, ...}: {
        imports = [
          ./fish
          ./bash
        ];

        config = {
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
