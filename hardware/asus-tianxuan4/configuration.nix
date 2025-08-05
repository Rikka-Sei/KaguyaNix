{
  config,
  pkgs,
  ...
}: {
  imports = [./hardware-configuration.nix];

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

  # 设备特定的硬件配置
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # 音频配置
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ASUS 特定服务
  services.asusd.enable = true;

  # 图形支持
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA offload 脚本
  environment.systemPackages = with pkgs; [
    supergfxctl # asus gfx
    qemu # 多架构支持

    (writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];

  # 多架构支持配置
  boot.binfmt.emulatedSystems = ["aarch64-linux"];
  nix.settings.extra-platforms = ["aarch64-linux"];
}
