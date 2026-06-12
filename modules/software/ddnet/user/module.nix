{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.ddnet;
in {
  options.kaguya.software.ddnet.enable = lib.mkEnableOption "ddnet 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.ddnet];
  };
}
