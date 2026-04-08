{
  config,
  lib,
  ...
}: let
  cfg = config.kaguya.software.workstation;
in {
  options.kaguya.software.workstation.enable = lib.mkEnableOption "桌面工作站软件聚合能力";

  config = lib.mkIf cfg.enable {};
}
