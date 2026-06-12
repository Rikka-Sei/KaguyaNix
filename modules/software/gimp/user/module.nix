{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.gimp;
in {
  options.kaguya.software.gimp.enable = lib.mkEnableOption "gimp 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.gimp];
  };
}
