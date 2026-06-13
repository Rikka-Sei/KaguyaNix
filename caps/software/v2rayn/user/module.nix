{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.v2rayn;
in {
  options.kaguya.software.v2rayn.enable = lib.mkEnableOption "v2rayn 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.v2rayn];
  };
}
