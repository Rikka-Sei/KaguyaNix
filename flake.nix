{
  description = "Rikki 's NixOS Flake";

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

    nil = {
      url = "github:oxalica/nil";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-flatpak,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        "ASUS_TianXuan4_Rikki" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules =
            [
              nix-flatpak.nixosModules.nix-flatpak
              home-manager.nixosModules.home-manager
              ./plugin
            ]
            ++ [
              # Desktop
              ./desktop/gnome

              # device
              ./device/ASUS_TianXuan4

              # layers
              ./layer/develop

              ./layer/flatpak
              ./layer/home-manager

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
