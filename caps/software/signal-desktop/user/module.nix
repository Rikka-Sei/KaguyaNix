{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software."signal-desktop";
in {
  options.kaguya.software."signal-desktop".enable = lib.mkEnableOption "signal-desktop 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.signal-desktop];
  };
}
