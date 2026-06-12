{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.anki;
in {
  options.kaguya.software.anki.enable = lib.mkEnableOption "anki 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.anki];
  };
}
