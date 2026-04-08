{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaguya.services.vm;
in {
  options.kaguya.services.vm.enable = lib.mkEnableOption "虚拟化能力";

  config = lib.mkIf cfg.enable {
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
            })
            .fd
          ];
        };
      };
    };

    virtualisation.spiceUSBRedirection.enable = true;

    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      qemu
      OVMF
      gvfs
      dnsmasq
    ];
  };
}
