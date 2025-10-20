{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.docker-compose
  ];

  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    daemon.settings = {
      proxies = {
        http-proxy = "http://127.0.0.1:20171";
        https-proxy = "http://127.0.0.1:20171";
        no-proxy = "127.0.0.1";
        mtu = 1400;
      };
    };
  };

  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-ip6tables" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
  };

  boot.kernelModules = [ "br_netfilter" ];

  # 注意：用户组配置移到用户配置中
  users.extraGroups.docker.members = [ "username-with-access-to-socket" ];
}
