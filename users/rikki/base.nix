{
  pkgs,
  inputs,
  ...
}: let
  userName = "rikki";
  stateVersion = "24.05";
in {
  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "vboxusers"
      "libvirt"
      "kvm"
    ];
  };

  # GPG 配置
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  # Home Manager 基础配置
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };

  home-manager.users.${userName} = {
    home.username = "${userName}";
    home.homeDirectory = "/home/${userName}";
    home.stateVersion = "${stateVersion}";
    programs.home-manager.enable = true;
  };
}
