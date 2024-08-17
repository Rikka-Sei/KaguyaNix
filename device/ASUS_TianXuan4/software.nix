{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    asusctl     # asus control
    supergfxctl # asus gfx
  ];
}