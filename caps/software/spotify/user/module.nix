{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.spotify;
in {
  options.kaguya.software.spotify.enable = lib.mkEnableOption "spotify 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.spotify];
  };
}
