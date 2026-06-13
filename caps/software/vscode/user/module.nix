{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.vscode;
in {
  options.kaguya.software.vscode.enable = lib.mkEnableOption "vscode 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.vscode];
  };
}
