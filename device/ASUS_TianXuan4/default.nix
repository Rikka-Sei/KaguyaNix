{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
  ];

  # System variables
  environment.variables = { };

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Device Control kit
  environment.systemPackages = with pkgs; [
    supergfxctl # asus gfx

    (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];

  services.asusd = {
    enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  # 启用 OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 支持 32 位应用
  };

  # 加载 nvidia 驱动
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # 启用 modesetting（必需）
    modesetting.enable = true;

    # 电源管理（实验性功能，可能导致睡眠/挂起失败）
    # 如果遇到图形损坏或应用崩溃问题，可以启用
    powerManagement.enable = true;

    # 细粒度电源管理（实验性，仅适用于图灵架构或更新的 GPU）
    powerManagement.finegrained = true;

    # 使用开源内核模块（仅支持图灵架构及更新的 GPU）
    # 对于较旧的 GPU，设置为 false
    open = true;

    # 启用 NVIDIA 设置菜单
    nvidiaSettings = true;

    # 选择稳定版驱动
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME 配置
    prime = {
      # 使用 Offload 模式（推荐用于笔记本电脑）
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # 根据您的 lshw 输出配置 Bus ID
      # Intel: pci@0000:00:02.0 -> PCI:0:2:0
      intelBusId = "PCI:0:2:0";
      # NVIDIA: pci@0000:01:00.0 -> PCI:1:0:0
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
