{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software."gnome-software";
in {
  options.kaguya.software."gnome-software".enable = lib.mkEnableOption "gnome-software 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.gnome-software];
  };
}
