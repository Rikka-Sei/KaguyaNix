{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.vlc;
in {
  options.kaguya.software.vlc.enable = lib.mkEnableOption "vlc 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.vlc];
  };
}
