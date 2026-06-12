{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.gnucash;
in {
  options.kaguya.software.gnucash.enable = lib.mkEnableOption "gnucash 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.gnucash];
  };
}
