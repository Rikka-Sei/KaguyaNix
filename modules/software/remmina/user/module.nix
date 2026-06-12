{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.remmina;
in {
  options.kaguya.software.remmina.enable = lib.mkEnableOption "remmina 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.remmina];
  };
}
