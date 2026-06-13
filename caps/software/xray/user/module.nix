{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.xray;
in {
  options.kaguya.software.xray.enable = lib.mkEnableOption "xray 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.xray];
  };
}
