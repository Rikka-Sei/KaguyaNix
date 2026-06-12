{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.software.thunderbird;
in {
  options.kaguya.software.thunderbird.enable = lib.mkEnableOption "thunderbird 软件能力";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.thunderbird];
  };
}
