{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kaguya.software."desktop-tools";
in
{
  options.kaguya.software."desktop-tools".enable = lib.mkEnableOption "桌面工具软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals pkgs.stdenv.isLinux [
      pkgs.gnome-software
    ];
  };
}
