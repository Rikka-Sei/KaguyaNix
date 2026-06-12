{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.calibre;
in {
  options.kaguya.software.calibre.enable = lib.mkEnableOption "calibre 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.calibre];
  };
}
