{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.core.user-cli;
in {
  options.kaguya.core.user-cli.enable = lib.mkEnableOption "用户基础 CLI 能力";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bc
      jq
      fastfetch
    ];
  };
}
