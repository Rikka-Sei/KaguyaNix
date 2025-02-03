{ pkgs, ... }:
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
  ];

  # System variables
  environment.variables = { };

  # Sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Device Control kit
  environment.systemPackages = with pkgs; [
    supergfxctl # asus gfx
  ];

  services.asusd = {
    enable = true;
  };

  # NVIDIA
  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware.opengl.extraPackages = with pkgs; [
    intel-compute-runtime
    intel-media-driver
  ];
}
