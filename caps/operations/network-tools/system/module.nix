{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.operations.network-tools;
in {
  options.kaguya.operations.network-tools.enable = lib.mkEnableOption "网络排障工具能力";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mtr
      iperf3
      dnsutils
      aria2
      nmap
      ipcalc
      netcat-gnu
    ];
  };
}
