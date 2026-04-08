{
  config,
  lib,
  ...
}: let
  cfg = config.kaguya.services.virtualbox;
in {
  options.kaguya.services.virtualbox.enable = lib.mkEnableOption "VirtualBox 能力";

  config = lib.mkIf cfg.enable {
    virtualisation.virtualbox.host.enable = true;
    virtualisation.virtualbox.guest.enable = true;
    virtualisation.virtualbox.guest.dragAndDrop = true;
  };
}
