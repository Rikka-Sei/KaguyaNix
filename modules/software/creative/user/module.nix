{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.creative;
in {
  options.kaguya.software.creative.enable = lib.mkEnableOption "创作软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        gimp
        typst
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        kdePackages.kdenlive
        typora
      ];
  };
}
