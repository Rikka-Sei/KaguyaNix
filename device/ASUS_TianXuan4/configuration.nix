{ pkgs, ... }:
{
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      default = "0";
      efiSupport = true;
      extraEntries = ''
        menuentry "Windows" --class windows {
          search --file --no-floppy --set=root /EFI/Microsoft/Boot/bootmgfw.efi
          chainloader (''${root})/EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
      extraConfig = ''
        set theme=/grub/Arknights_Shu_5806/theme.txt;
      '';
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  networking = {
    hostName = "ASUS_TianXuan4-NixOS"; # please config in user configurations
    networkmanager.enable = true;
  };

  networking.firewall = {
    enable = false;
  };

  time.timeZone = "Asia/Shanghai";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.trusted-users = [
    "root"
    "rikki"
  ];

  # 启用 QEMU 用户模式模拟
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # 配置 Nix 设置
  nix.settings = {
    # 允许额外的平台
    extra-platforms = [ "aarch64-linux" ];
  };

  # 确保 QEMU 可用
  environment.systemPackages = with pkgs; [
    qemu
  ];

  system.stateVersion = "24.05";
}
