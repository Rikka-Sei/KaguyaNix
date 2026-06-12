{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.typora;
in {
  options.kaguya.software.typora.enable = lib.mkEnableOption "typora 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.typora];
  };
}
