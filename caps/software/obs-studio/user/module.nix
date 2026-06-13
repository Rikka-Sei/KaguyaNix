{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software."obs-studio";
in {
  options.kaguya.software."obs-studio".enable = lib.mkEnableOption "obs-studio 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.obs-studio];
  };
}
