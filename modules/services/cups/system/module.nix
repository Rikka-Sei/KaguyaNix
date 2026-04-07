{ config, lib, ... }:
let
  cfg = config.kaguya.services.cups;
in
{
  options.kaguya.services.cups.enable = lib.mkEnableOption "打印服务能力";

  config = lib.mkIf cfg.enable {
    services.printing.enable = true;
  };
}
