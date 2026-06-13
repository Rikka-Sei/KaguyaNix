{
  config,
  lib,
  ...
}: let
  cfg = config.kaguya.services.vmware;
in {
  options.kaguya.services.vmware.enable = lib.mkEnableOption "VMware 能力";

  config = lib.mkIf cfg.enable {
    virtualisation.vmware.host.enable = true;
  };
}
