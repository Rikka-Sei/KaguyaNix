# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      default = "1";
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

  networking.nameservers = [ "119.29.29.29" "2402:4e00::" ];

  time.timeZone = "Asia/Shanghai";

  # ---------------------------- hyprland ------------------------------
  # programs.hyprland = {
  #   enable = true;
  #   xwayland.enable = true;
  #   package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  # };
  # ------------------------------------------------------------------

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # Nix Flakes 通过 git 命令从数据源拉取依赖，所以必须先安装好 git -> See programs.nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings = {
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.bfsu.edu.cn/nix-channels/store"
    ];
  };

  system.stateVersion = "24.05";
}

