{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.filezilla;
in {
  options.kaguya.software.filezilla.enable = lib.mkEnableOption "filezilla 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.filezilla];
  };
}
