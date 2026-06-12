{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software."gemini-cli";
in {
  options.kaguya.software."gemini-cli".enable = lib.mkEnableOption "gemini-cli 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.gemini-cli];
  };
}
