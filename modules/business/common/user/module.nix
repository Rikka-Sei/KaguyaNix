{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.business.common;
in {
  options.kaguya.business.common.enable = lib.mkEnableOption "办公软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals pkgs.stdenv.isLinux [
      pkgs.gnucash
    ];
  };
}
