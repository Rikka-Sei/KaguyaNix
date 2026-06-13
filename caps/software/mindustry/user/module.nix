{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.mindustry;
in {
  options.kaguya.software.mindustry.enable = lib.mkEnableOption "mindustry 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.mindustry];
  };
}
