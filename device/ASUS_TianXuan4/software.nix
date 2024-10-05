{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    supergfxctl # asus gfx
  ];

  services.asusd = {
    enable = true;
  };
}
