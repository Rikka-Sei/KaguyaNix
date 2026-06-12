{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.treefmt;
in {
  options.kaguya.software.treefmt.enable = lib.mkEnableOption "treefmt 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.treefmt];
  };
}
