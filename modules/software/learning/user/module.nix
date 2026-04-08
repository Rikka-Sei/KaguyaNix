{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kaguya.software.learning;
in
{
  options.kaguya.software.learning.enable = lib.mkEnableOption "学习软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals pkgs.stdenv.isLinux (
      with pkgs;
      [
        anki
        calibre
      ]
    );
  };
}
