{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.typst;
in {
  options.kaguya.software.typst.enable = lib.mkEnableOption "typst 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.typst];
  };
}
