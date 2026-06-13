{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.services.docker;
in {
  options.kaguya.services.docker = {
    enable = lib.mkEnableOption "Docker 服务能力";
    storageDriver = lib.mkOption {
      type = lib.types.str;
      default = "btrfs";
      description = "Docker 存储驱动。";
    };
    proxy = {
      http = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:20171";
      };
      https = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:20171";
      };
      noProxy = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };
      mtu = lib.mkOption {
        type = lib.types.int;
        default = 1400;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.docker-compose];

    virtualisation.docker = {
      enable = true;
      storageDriver = cfg.storageDriver;
      daemon.settings = {
        proxies = {
          "http-proxy" = cfg.proxy.http;
          "https-proxy" = cfg.proxy.https;
          "no-proxy" = cfg.proxy.noProxy;
          mtu = cfg.proxy.mtu;
        };
      };
    };

    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;
    };

    boot.kernelModules = ["br_netfilter"];
  };
}
