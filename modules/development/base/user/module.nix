{
  config,
  lib,
  ...
}:
let
  cfg = config.kaguya.development.base;
  scriptsDir = ./scripts;
  scriptFiles = builtins.readDir scriptsDir;
  deployScripts = lib.mapAttrs' (
    name: _:
    lib.nameValuePair ".local/bin/${lib.removeSuffix ".sh" name}" {
      source = scriptsDir + "/${name}";
      executable = true;
    }
  ) (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".sh" name) scriptFiles);
in
{
  options.kaguya.development.base.enable = lib.mkEnableOption "基础开发用户能力";

  config = lib.mkIf cfg.enable {
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.opencode/bin"
    ];

    programs.fish = {
      enable = true;
      shellAliases = {
        "0file" = "curl -F\"file=@$1\" https://envs.sh";
        "0pb" = "curl -F\"file=@-;\" https://envs.sh";
        "0url" = "curl -F\"url=$1\" https://envs.sh";
        "0short" = "curl -F\"shorten=$1\" https://envs.sh";
      };
      interactiveShellInit = ''
        set fish_greeting
      '';
    };

    home.file = deployScripts;

    programs.starship.enable = true;
  };
}
