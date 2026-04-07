{ config, lib, ... }:
let
  cfg = config.kaguya.services.tailscale;
in
{
  options.kaguya.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale 能力";
    useRoutingFeatures = lib.mkOption {
      type = lib.types.str;
      default = "both";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      inherit (cfg) useRoutingFeatures;
    };
  };
}
