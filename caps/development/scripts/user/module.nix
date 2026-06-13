{
  config,
  lib,
  ...
}: let
  cfg = config.kaguya.development.scripts;
  scriptsDir = ./scripts;
  scriptFiles = builtins.readDir scriptsDir;
  deployScripts = lib.mapAttrs' (
    name: _:
      lib.nameValuePair ".local/bin/${lib.removeSuffix ".sh" name}" {
        source = scriptsDir + "/${name}";
        executable = true;
      }
  ) (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".sh" name) scriptFiles);
in {
  options.kaguya.development.scripts.enable = lib.mkEnableOption "开发脚本与 shell 引导能力";

  config = lib.mkIf cfg.enable {
    home.file = deployScripts;
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
    programs.starship.enable = true;
  };
}
