{
  pkgs,
  config,
  lib,
  ...
}:
{
  # 根据 NixOS Wiki 官方文档的配置
  programs.virt-manager.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;

  environment = {
    systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      qemu
      OVMF
      gvfs
      dnsmasq
    ];
  };

  # 动态将系统配置中定义的所有用户添加到 libvirtd 组
  users.users = lib.mkMerge (
    lib.mapAttrsToList (username: userCfg: {
      ${username}.extraGroups = [ "libvirtd" ];
    }) (config.systemConfig.users or { })
  );
}
