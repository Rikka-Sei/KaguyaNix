{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.operations.system-diagnostics;
in {
  options.kaguya.operations.system-diagnostics.enable = lib.mkEnableOption "系统诊断工具能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        btop
        iftop
        lsof
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        iotop
        strace
        ltrace
        sysstat
        lm_sensors
        ethtool
        pciutils
        usbutils
        mission-center
      ];
  };
}
