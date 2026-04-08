{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.browser;
in {
  options.kaguya.software.browser.enable = lib.mkEnableOption "浏览器软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        firefox
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        tor-browser
      ];
  };
}
