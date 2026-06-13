{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software."tor-browser";
in {
  options.kaguya.software."tor-browser".enable = lib.mkEnableOption "tor-browser 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.tor-browser];
  };
}
