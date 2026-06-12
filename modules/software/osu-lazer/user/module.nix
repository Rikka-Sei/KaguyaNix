{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software."osu-lazer";
in {
  options.kaguya.software."osu-lazer".enable = lib.mkEnableOption "osu-lazer 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.osu-lazer-bin];
  };
}
