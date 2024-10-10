{
  description = "HenryZeng 's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-flatpak,
    alejandra,
    ...
  } @ inputs: {
    nixosConfigurations = {
      "ASUS_TianXuan4_Rikki" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # device
          ./device/ASUS_TianXuan4

          # layers
          ./layer/develop
          ./layer/gnome
          ./layer/flatpak
          ./layer/home-manager

          # plugin
          ./plugin/font/laptop
          ./plugin/input/fcitx5

          # extra services
          ./plugin/services/tailscale
          ./plugin/services/virtualbox
          ./plugin/services/vm

          # users
          ./users/rikki-laptop
        ];
      };
    };
  };
}
