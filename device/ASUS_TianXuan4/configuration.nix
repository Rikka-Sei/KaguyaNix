{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

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

  networking.nameservers = ["119.29.29.29" "2402:4e00::"];

  time.timeZone = "Asia/Shanghai";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
    ];
  };

  system.stateVersion = "24.05";
}
