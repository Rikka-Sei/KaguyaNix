{
  description = "Rikki 's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    nil.url = "github:oxalica/nil";
  };

  outputs =
    {
      self,
      nixpkgs-unstable,
      nixpkgs,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        "ASUS_TianXuan4_Rikki" =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            };
            modules =
              [
                ./plugin
              ]
              ++ [
                {
                  nixpkgs.config.allowUnfree = true;
                }
                # Desktop
                ./desktop/gnome

                # device
                ./device/ASUS_TianXuan4

                # layers
                ./layer/develop

                ./layer/flatpak
                ./plugin/services/vm

                # users
                ./users/rikki-laptop
              ];
          };
      };
    };
}
