{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software."sing-box";
in {
  options.kaguya.software."sing-box".enable = lib.mkEnableOption "sing-box 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.sing-box];
  };
}
