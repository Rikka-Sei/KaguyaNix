{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.firefox;
in {
  options.kaguya.software.firefox.enable = lib.mkEnableOption "firefox 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.firefox];
  };
}
