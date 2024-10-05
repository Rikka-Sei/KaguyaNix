{pkgs, ...}: {
  services.xserver.videoDrivers = ["modesetting" "nvidia"];

  hardware.opengl.extraPackages = with pkgs; [
    intel-compute-runtime
    intel-media-driver
  ];
}
