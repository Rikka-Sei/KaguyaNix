{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software."base-cli";
in {
  options.kaguya.software."base-cli".enable = lib.mkEnableOption "基础命令行软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bc
      jq
      fastfetch
    ];
  };
}
