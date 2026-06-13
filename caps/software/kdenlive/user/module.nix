{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.kdenlive;
in {
  options.kaguya.software.kdenlive.enable = lib.mkEnableOption "kdenlive 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.kdePackages.kdenlive];
  };
}
